-- ==============================================================================
--  GIT REVIEW  -  "show me everything the last N commits touched"
--
--  The tidy-up workflow: you have a stack of unpushed commits and you want to
--  read and edit the *current* state of every file they touched, with the
--  changes marked in the gutter. Not a side-by-side diff (that is diffview,
--  this deliberately does not use it) - just your normal editable buffers.
--
--  Three parts:
--    signs  - gitsigns.change_base(sha, true). The `true` is global, so every
--             buffer you open is diffed against the same base. This is the bit
--             people miss: gitsigns is not per-file.
--    panel  - a left sidebar with the changed files as a directory tree, in
--             the style of diffview's file panel. Single-child directories are
--             collapsed into one line (RecoHGCal/TICL/plugins) or the CMSSW
--             tree wastes half the width on indentation.
--    index  - `git blame` per line, mapped onto the commit range, rendered as
--             a small number at end of line. 1 = newest commit, N = oldest.
--             So the gutter says "this line changed" and the number says
--             "and it was commit 3 of 4 that did it".
--
--  The base is resolved to a concrete SHA at invoke time rather than kept as
--  the literal "HEAD~4". During a tidy session you will amend and commit, which
--  moves HEAD - a pinned SHA keeps the review fixed on the same starting point
--  instead of sliding along under you. Re-run :GitReview to re-anchor.
-- ==============================================================================

local M = {}

local ns = vim.api.nvim_create_namespace("gitreview")
local ns_panel = vim.api.nvim_create_namespace("gitreview_panel")
local group = vim.api.nvim_create_augroup("GitReview", { clear = true })

local PANEL_WIDTH = 42

-- base      : SHA of the commit *before* the series
-- label     : how the user spelled it ("HEAD~4")
-- index     : { [sha] = n }, n = 1 for the newest commit in the range
-- tree      : root node of the file tree
-- rows      : panel line number -> node
-- collapsed : { [dirpath] = true }
local state = {
  base = nil,
  label = nil,
  index = nil,
  tree = nil,
  rows = {},
  collapsed = {},
  win = nil,
  buf = nil,
  target_win = nil,
  files = {}, -- ordered, matches the panel; drives <Tab> / <S-Tab>
  fileset = {}, -- absolute path -> position in state.files
  current = nil, -- abs path of the file being viewed; highlighted in the panel
  diff_win = nil, -- the gD scratch window, so the same key can close it
}

-- Age ramp for the commit index: newest is brightest and bold, older fades to
-- grey. Positions past the end of the ramp clamp to the last (dimmest) entry,
-- so :GitReview 20 still renders sensibly.
local AGE_COLORS = {
  { fg = "#fabd2f", bold = true }, -- 1  newest
  { fg = "#fe8019" }, -- 2
  { fg = "#d79921" }, -- 3
  { fg = "#b57614" }, -- 4
  { fg = "#a89984" }, -- 5
  { fg = "#7c6f64" }, -- 6+ oldest
}

for i, c in ipairs(AGE_COLORS) do
  vim.api.nvim_set_hl(0, "GitReviewAge" .. i, vim.tbl_extend("force", c, { default = true }))
end

vim.api.nvim_set_hl(0, "GitReviewIndex", { link = "Comment", default = true })
vim.api.nvim_set_hl(0, "GitReviewDirty", { link = "WarningMsg", default = true })
vim.api.nvim_set_hl(0, "GitReviewDir", { link = "Directory", default = true })
vim.api.nvim_set_hl(0, "GitReviewAdd", { link = "DiffAdd", default = true })
vim.api.nvim_set_hl(0, "GitReviewDel", { link = "DiffDelete", default = true })
vim.api.nvim_set_hl(0, "GitReviewTitle", { link = "Title", default = true })
vim.api.nvim_set_hl(0, "GitReviewCurrent", { link = "Visual", default = true })

-- ---------------------------------------------------------------------------
-- git helpers
-- ---------------------------------------------------------------------------

-- Run git in the repo owning the given file, not nvim's cwd - the worktrees
-- under refs/ mean those are not always the same place.
local function git(args, path)
  local dir = path and vim.fn.fnamemodify(path, ":h") or vim.fn.expand("%:p:h")
  if dir == "" or vim.fn.isdirectory(dir) == 0 then
    dir = vim.fn.getcwd()
  end
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  if vim.v.shell_error ~= 0 then
    return nil, table.concat(out, "\n")
  end
  return out
end

--- Files changed between `base` and the working tree, with +/- counts.
--- Working tree (not HEAD) is deliberate: uncommitted tidying shows up too.
local function changed_files(base)
  local root = git({ "rev-parse", "--show-toplevel" })
  if not root then
    return nil, "not inside a git repository"
  end
  root = root[1]

  local out, err = git({ "diff", "--numstat", base })
  if not out then
    return nil, err
  end

  local files = {}
  for _, line in ipairs(out) do
    -- numstat: "<added>\t<removed>\t<path>"; binary files report "-\t-\t<path>"
    local added, removed, path = line:match("^(%S+)\t(%S+)\t(.+)$")
    if path then
      -- rename form: "old => new" or "dir/{a => b}/f" - take the new path
      local renamed = path:match("=>%s*(.-)%s*}") or path:match("=>%s*(.+)$")
      if renamed then
        path = ((path:match("^(.-){") or "") .. renamed):gsub("//", "/")
      end
      table.insert(files, { path = root .. "/" .. path, rel = path, added = added, removed = removed })
    end
  end

  table.sort(files, function(a, b)
    return a.rel < b.rel
  end)
  return files
end

--- Map every commit in base..HEAD to its position, newest first.
--- rev-list already returns newest-first, so the ordinal is just the index.
local function build_index(base)
  local out, err = git({ "rev-list", base .. "..HEAD" })
  if not out then
    return nil, err
  end
  local index = {}
  for i, sha in ipairs(out) do
    index[sha] = i
  end
  return index, #out
end

-- ---------------------------------------------------------------------------
-- tree construction
-- ---------------------------------------------------------------------------

local function new_dir(name, path)
  return { kind = "dir", name = name, path = path, dirs = {}, order = {}, files = {} }
end

--- Collapse chains of single-child directories: a dir with exactly one
--- subdirectory and no files of its own merges into its child. This is what
--- makes the panel readable in CMSSW, where paths are 4-5 levels deep.
local function compress(node)
  for _, name in ipairs(node.order) do
    compress(node.dirs[name])
  end
  while #node.order == 1 and #node.files == 0 do
    local only = node.dirs[node.order[1]]
    node.name = node.name == "" and only.name or (node.name .. "/" .. only.name)
    node.path = only.path
    node.dirs, node.order, node.files = only.dirs, only.order, only.files
  end
end

local function build_tree(files)
  local root = new_dir("", "")
  for _, f in ipairs(files) do
    local parts = vim.split(f.rel, "/", { plain = true })
    local node, acc = root, {}
    for i = 1, #parts - 1 do
      table.insert(acc, parts[i])
      local key = parts[i]
      if not node.dirs[key] then
        node.dirs[key] = new_dir(key, table.concat(acc, "/"))
        table.insert(node.order, key)
      end
      node = node.dirs[key]
    end
    table.insert(node.files, {
      kind = "file",
      name = parts[#parts],
      path = f.path,
      rel = f.rel,
      added = f.added,
      removed = f.removed,
    })
  end
  compress(root)
  return root
end

-- ---------------------------------------------------------------------------
-- panel rendering
-- ---------------------------------------------------------------------------

local function devicon(name)
  local ok, di = pcall(require, "nvim-web-devicons")
  if not ok then
    return nil, nil
  end
  local icon, hl = di.get_icon(name, vim.fn.fnamemodify(name, ":e"), { default = true })
  return icon, hl
end

--- Flatten the tree into display lines, recording which node each line maps to
--- so <CR> knows what was clicked.
local function flatten(node, depth, lines, hls, rows)
  local pad = string.rep("  ", depth)

  for _, name in ipairs(node.order) do
    local d = node.dirs[name]
    local open = not state.collapsed[d.path]
    local text = pad .. (open and " " or " ") .. d.name .. "/"
    table.insert(lines, text)
    table.insert(hls, { { #pad, -1, "GitReviewDir" } })
    rows[#lines] = d
    if open then
      flatten(d, depth + 1, lines, hls, rows)
    end
  end

  for _, f in ipairs(node.files) do
    local icon, ihl = devicon(f.name)
    local prefix = pad .. "  " .. (icon and (icon .. " ") or "")
    local counts = string.format("+%s -%s", f.added, f.removed)

    -- Right-align the counts into a fixed column. CMSSW filenames are long
    -- enough to blow past the panel width, so truncate the name rather than
    -- let the counts drift - a ragged stat column is much harder to scan.
    local budget = PANEL_WIDTH - 2 - #prefix - #counts - 1
    local name = f.name
    if budget < 4 then
      budget = 4
    end
    if #name > budget then
      name = name:sub(1, budget - 1) .. "…"
    end

    local body = prefix .. name
    local gap = math.max(1, PANEL_WIDTH - 2 - #body - #counts)
    local text = body .. string.rep(" ", gap) .. counts
    table.insert(lines, text)

    local h = {}
    if icon and ihl then
      table.insert(h, { #pad + 2, #pad + 2 + #icon, ihl })
    end
    local cstart = #body + gap
    local plus_end = cstart + #("+" .. f.added)
    table.insert(h, { cstart, plus_end, "GitReviewAdd" })
    table.insert(h, { plus_end, -1, "GitReviewDel" })
    table.insert(hls, h)
    rows[#lines] = f
  end
end

local function render()
  if not (state.buf and vim.api.nvim_buf_is_valid(state.buf)) then
    return
  end

  local lines, hls, rows = {}, {}, {}
  local title = string.format("Changed since %s", state.label or "?")
  table.insert(lines, title)
  table.insert(hls, { { 0, -1, "GitReviewTitle" } })
  table.insert(lines, "")
  table.insert(hls, {})

  flatten(state.tree, 0, lines, hls, rows)
  state.rows = rows

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(state.buf, ns_panel, 0, -1)
  for lnum, spec in ipairs(hls) do
    for _, h in ipairs(spec) do
      pcall(vim.api.nvim_buf_set_extmark, state.buf, ns_panel, lnum - 1, h[1], {
        end_col = h[2] == -1 and #lines[lnum] or math.min(h[2], #lines[lnum]),
        hl_group = h[3],
      })
    end
  end

  -- Mark the file you are actually looking at. 'cursorline' alone is not
  -- enough: it is dimmed in an unfocused window, which the panel almost always
  -- is, so the whole point (seeing where you are in the set) would be lost.
  for lnum, node in pairs(state.rows) do
    if node.kind == "file" and node.path == state.current then
      pcall(vim.api.nvim_buf_set_extmark, state.buf, ns_panel, lnum - 1, 0, {
        line_hl_group = "GitReviewCurrent",
      })
    end
  end
end

--- Point the panel at `path`: expand any collapsed parent directories, move the
--- panel cursor onto its row and highlight it. Never steals focus - the cursor
--- is set on the panel window while you stay in the file.
local function reveal(path)
  if not (state.win and vim.api.nvim_win_is_valid(state.win)) then
    return
  end
  local entry = state.fileset[path] and state.files[state.fileset[path]]
  if not entry then
    return
  end

  state.current = path

  -- A collapsed ancestor means the file has no row to jump to, so open the
  -- chain first. Directory paths are relative, like the file's `rel`.
  for dir in pairs(state.collapsed) do
    if entry.rel:sub(1, #dir + 1) == dir .. "/" then
      state.collapsed[dir] = nil
    end
  end
  render()

  for lnum, node in pairs(state.rows) do
    if node.kind == "file" and node.path == path then
      pcall(vim.api.nvim_win_set_cursor, state.win, { lnum, 0 })
      return
    end
  end
end

--- Pick a window to open files into: the one we came from, else any window
--- that is not the panel, else make one.
local function target_window()
  if state.target_win and vim.api.nvim_win_is_valid(state.target_win) and state.target_win ~= state.win then
    return state.target_win
  end
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
      state.target_win = w
      return w
    end
  end
  vim.cmd("vsplit")
  state.target_win = vim.api.nvim_get_current_win()
  return state.target_win
end

local function on_select()
  local node = state.rows[vim.api.nvim_win_get_cursor(0)[1]]
  if not node then
    return
  end
  if node.kind == "dir" then
    state.collapsed[node.path] = not state.collapsed[node.path]
    local pos = vim.api.nvim_win_get_cursor(0)
    render()
    pcall(vim.api.nvim_win_set_cursor, 0, pos)
  else
    local win = target_window()
    vim.api.nvim_set_current_win(win)
    vim.cmd("edit " .. vim.fn.fnameescape(node.path))
  end
end

local function open_panel()
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    render()
    return
  end

  state.target_win = vim.api.nvim_get_current_win()

  vim.cmd("topleft vsplit")
  state.win = vim.api.nvim_get_current_win()
  state.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(state.win, state.buf)
  vim.api.nvim_win_set_width(state.win, PANEL_WIDTH)

  vim.bo[state.buf].buftype = "nofile"
  vim.bo[state.buf].bufhidden = "hide"
  vim.bo[state.buf].swapfile = false
  vim.bo[state.buf].filetype = "GitReview"
  vim.api.nvim_buf_set_name(state.buf, "GitReview")

  local wo = vim.wo[state.win]
  wo.number, wo.relativenumber = false, false
  wo.signcolumn, wo.foldcolumn = "no", "0"
  wo.wrap, wo.cursorline, wo.winfixwidth = false, true, true
  wo.list = false

  local function map(lhs, fn)
    vim.keymap.set("n", lhs, fn, { buffer = state.buf, nowait = true, silent = true })
  end
  map("<CR>", on_select)
  map("o", on_select)
  map("<2-LeftMouse>", on_select)
  map("q", function()
    M.close()
  end)
  map("R", function()
    M.open(state.label)
  end)

  render()
end

-- ---------------------------------------------------------------------------
-- navigation
-- ---------------------------------------------------------------------------

--- Cycle through the changed files in panel order. Wraps at both ends.
local function goto_file(step)
  if #state.files == 0 then
    return
  end
  local here = state.fileset[vim.api.nvim_buf_get_name(0)]
  -- not in the set (or sitting in the panel): start at the first file
  local nxt = here and ((here - 1 + step) % #state.files) + 1 or (step > 0 and 1 or #state.files)

  local win = vim.api.nvim_get_current_win()
  if win == state.win then
    win = target_window()
    vim.api.nvim_set_current_win(win)
  end
  vim.cmd("edit " .. vim.fn.fnameescape(state.files[nxt].path))
  vim.notify(string.format("[%d/%d] %s", nxt, #state.files, state.files[nxt].rel), vim.log.levels.INFO)
end

--- Float showing the commit that last touched the line under the cursor, with
--- that commit's diff for this file. Answers "where did this line come from"
--- without leaving the buffer.
local function line_commit()
  local path = vim.api.nvim_buf_get_name(0)
  local lnum = vim.api.nvim_win_get_cursor(0)[1]

  -- blame reads the file on disk, so on a modified buffer the line numbers
  -- would be stale; gitsigns' own preview works off the buffer, so defer to it
  if vim.bo.modified then
    local ok, gs = pcall(require, "gitsigns")
    if ok then
      gs.preview_hunk()
    end
    return
  end

  local blame = git({ "blame", "-L", lnum .. "," .. lnum, "--porcelain", "--", path }, path)
  if not blame or not blame[1] then
    return
  end
  local sha = blame[1]:match("^(%x+)")
  if not sha then
    return
  end

  -- uncommitted line: the interesting diff is the working one, not a commit
  if sha:match("^0+$") then
    local ok, gs = pcall(require, "gitsigns")
    if ok then
      gs.preview_hunk()
    end
    return
  end

  local info = git({ "show", "-s", "--format=%h  %s%n%an, %ar", sha }, path)
  local diff = git({ "show", "--no-color", "--format=", sha, "--", path }, path)
  if not info then
    return
  end

  local n = state.index and state.index[sha]
  local header = n and string.format("commit %d of %d in range", n, vim.tbl_count(state.index))
    or "outside the reviewed range"

  local lines = { header, "" }
  vim.list_extend(lines, info)
  vim.list_extend(lines, { "" })
  vim.list_extend(lines, diff or { "(no changes to this file in that commit)" })

  local width, height = 0, 0
  for _, l in ipairs(lines) do
    width = math.max(width, vim.fn.strdisplaywidth(l))
    height = height + 1
  end
  width = math.min(width + 2, math.floor(vim.o.columns * 0.8))
  height = math.min(height, math.floor(vim.o.lines * 0.7))

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].filetype = "diff"
  vim.bo[buf].modifiable = false

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "cursor",
    row = 1,
    col = 0,
    width = width,
    height = height,
    style = "minimal",
    border = "rounded",
    title = " " .. vim.fn.fnamemodify(path, ":t") .. ":" .. lnum .. " ",
    title_pos = "center",
  })
  vim.wo[win].wrap = false

  for _, k in ipairs({ "q", "<Esc>", "<CR>" }) do
    vim.keymap.set("n", k, function()
      pcall(vim.api.nvim_win_close, win, true)
    end, { buffer = buf, nowait = true, silent = true })
  end
end

--- Toggle a side-by-side diff of the current file against the review base.
--- Same key closes it, so it is a peek rather than a mode you get stuck in.
local function toggle_file_diff()
  if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
    pcall(vim.api.nvim_win_close, state.diff_win, true)
    state.diff_win = nil
    if vim.wo.diff then
      vim.cmd("diffoff")
    end
    return
  end
  if not state.base then
    return
  end

  local ok, gs = pcall(require, "gitsigns")
  if not ok then
    return
  end

  local before = {}
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    before[w] = true
  end
  -- gitsigns creates the scratch window itself; capture whichever one is new
  -- so the same key can close exactly that window later.
  gs.diffthis(state.base, {}, function()
    vim.schedule(function()
      for _, w in ipairs(vim.api.nvim_list_wins()) do
        if not before[w] then
          state.diff_win = w
          return
        end
      end
    end)
  end)
end

--- Buffer-local keys, attached only to files that are part of the review and
--- only while one is active. <Tab> shadows <C-i> (jumplist forward) in a
--- terminal, so keeping it scoped this tightly matters - :GitReviewOff puts
--- the key back everywhere.
local function attach_keys(bufnr)
  if not state.fileset[vim.api.nvim_buf_get_name(bufnr)] then
    return
  end
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = bufnr, silent = true, desc = desc })
  end
  map("<Tab>", function() goto_file(1) end, "GitReview: next file")
  map("<S-Tab>", function() goto_file(-1) end, "GitReview: prev file")
  map("<CR>", line_commit, "GitReview: commit behind this line")
  map("gD", toggle_file_diff, "GitReview: toggle diff vs base")

  -- ]c / [c are vim's diff-mode hunk keys and are dead outside a diff, so
  -- they are free to reuse here. gitsigns' own ]h / [h keep working too.
  local ok, gs = pcall(require, "gitsigns")
  if ok then
    map("]c", function() gs.nav_hunk("next") end, "GitReview: next change")
    map("[c", function() gs.nav_hunk("prev") end, "GitReview: prev change")
  end
end

local function detach_keys(bufnr)
  for _, lhs in ipairs({ "<Tab>", "<S-Tab>", "]c", "[c", "<CR>", "gD" }) do
    pcall(vim.keymap.del, "n", lhs, { buffer = bufnr })
  end
end

-- ---------------------------------------------------------------------------
-- per-line commit index
-- ---------------------------------------------------------------------------

--- Annotate one buffer: end-of-line marker naming which commit last touched
--- each line. Lines whose blame falls outside the range get nothing, so only
--- the series' own changes are labelled.
local function annotate(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_loaded(bufnr) or bufnr == state.buf then
    return
  end
  vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
  if not state.index then
    return
  end

  local path = vim.api.nvim_buf_get_name(bufnr)
  if path == "" or vim.fn.filereadable(path) == 0 then
    return
  end
  -- Never blame a modified buffer: blame reads the file on disk, so the line
  -- numbers would be stale and the marks would land on the wrong lines.
  if vim.bo[bufnr].modified then
    return
  end

  -- --porcelain (not --line-porcelain) repeats only the sha/line header per
  -- line and omits the author/commit metadata, which is all we would discard.
  local out = git({ "blame", "--porcelain", "--", path }, path)
  if not out then
    return
  end

  local total = vim.api.nvim_buf_line_count(bufnr)
  for _, line in ipairs(out) do
    -- block header: "<sha> <origline> <finalline> [<numlines>]"
    local sha, final = line:match("^(%x+) %d+ (%d+)")
    if sha and final then
      local lnum = tonumber(final)
      if lnum and lnum <= total then
        local text, hl
        if sha:match("^0+$") then
          -- all-zero sha = not committed yet, i.e. your uncommitted tidying
          text, hl = " ▏~", "GitReviewDirty"
        elseif state.index[sha] then
          local n = state.index[sha]
          text = " ▏" .. n
          hl = "GitReviewAge" .. math.min(n, #AGE_COLORS)
        end
        if text then
          pcall(vim.api.nvim_buf_set_extmark, bufnr, ns, lnum - 1, 0, {
            virt_text = { { text, hl } },
            virt_text_pos = "eol",
            hl_mode = "combine",
          })
        end
      end
    end
  end
end

-- ---------------------------------------------------------------------------
-- commands
-- ---------------------------------------------------------------------------

--- :GitReview [N|revspec]  - default 4 commits back.
function M.open(arg)
  arg = (arg and arg ~= "") and arg or "4"
  -- bare number means "N commits back"; anything else is a literal revspec
  local revspec = arg:match("^%d+$") and ("HEAD~" .. arg) or arg

  local resolved, rerr = git({ "rev-parse", "--verify", revspec .. "^{commit}" })
  if not resolved then
    vim.notify("GitReview: cannot resolve " .. revspec .. "\n" .. (rerr or ""), vim.log.levels.ERROR)
    return
  end
  local base = resolved[1]

  local files, ferr = changed_files(base)
  if not files then
    vim.notify("GitReview: " .. (ferr or "failed to list files"), vim.log.levels.ERROR)
    return
  end
  if #files == 0 then
    vim.notify("GitReview: no files changed since " .. revspec, vim.log.levels.WARN)
    return
  end

  local index, ncommits = build_index(base)
  if not index then
    vim.notify("GitReview: " .. (ncommits or "could not list commits"), vim.log.levels.ERROR)
    return
  end

  state.base, state.label, state.index = base, revspec, index
  state.tree = build_tree(files)
  state.files, state.fileset = files, {}
  for i, f in ipairs(files) do
    state.fileset[f.path] = i
  end

  -- the signs half: global, so every buffer opened from the panel is marked
  local ok, gs = pcall(require, "gitsigns")
  if ok then
    gs.change_base(base, true)
  else
    vim.notify("GitReview: gitsigns not available, signs will be missing", vim.log.levels.WARN)
  end

  -- quickfix is still populated (so ]q / :cnext walk the same set) but not
  -- opened - the sidebar is the panel now.
  local items = {}
  for _, f in ipairs(files) do
    table.insert(items, { filename = f.path, lnum = 1, col = 1, text = string.format("+%s -%s", f.added, f.removed) })
  end
  vim.fn.setqflist({}, " ", { title = "GitReview " .. revspec, items = items })

  open_panel()

  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    annotate(b)
    attach_keys(b)
  end

  -- if the file you invoked from is part of the review, open already pointing
  -- at it rather than at the top of the tree
  local from = state.target_win
  if from and vim.api.nvim_win_is_valid(from) then
    reveal(vim.api.nvim_buf_get_name(vim.api.nvim_win_get_buf(from)))
  end

  vim.notify(
    string.format(
      "GitReview: %d files, %d commits since %s (%s)\n1 = newest, %d = oldest, ~ = uncommitted",
      #files,
      ncommits,
      revspec,
      base:sub(1, 9),
      ncommits
    ),
    vim.log.levels.INFO
  )
end

--- Drop back to the normal "uncommitted changes only" view.
function M.close()
  local ok, gs = pcall(require, "gitsigns")
  if ok then
    gs.reset_base(true)
  end

  if state.diff_win and vim.api.nvim_win_is_valid(state.diff_win) then
    pcall(vim.api.nvim_win_close, state.diff_win, true)
    state.diff_win = nil
  end
  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end
  if state.buf and vim.api.nvim_buf_is_valid(state.buf) then
    vim.api.nvim_buf_delete(state.buf, { force = true })
  end

  local panel_buf = state.buf
  for _, b in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_is_loaded(b) and b ~= panel_buf then
      vim.api.nvim_buf_clear_namespace(b, ns, 0, -1)
      detach_keys(b)
    end
  end

  state.base, state.label, state.index, state.tree = nil, nil, nil, nil
  state.rows, state.collapsed = {}, {}
  state.files, state.fileset, state.current = {}, {}, nil
  state.win, state.buf = nil, nil
  vim.fn.setqflist({}, "r")
  vim.notify("GitReview: off, base reset to index", vim.log.levels.INFO)
end

-- Re-annotate as you move around and as you save: writing a file changes which
-- lines are yours-uncommitted, so the numbers need to follow. Hanging the panel
-- sync off BufEnter (rather than off <Tab> itself) means the sidebar keeps up
-- however you arrived: <Tab>, <CR> in the panel, :edit, ]q, a telescope jump.
vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost" }, {
  group = group,
  callback = function(ev)
    if state.index then
      vim.schedule(function()
        annotate(ev.buf)
        attach_keys(ev.buf)
        reveal(vim.api.nvim_buf_get_name(ev.buf))
      end)
    end
  end,
})

-- Remember the last real window, so <CR> in the panel opens into the window
-- you were actually working in rather than a random one.
vim.api.nvim_create_autocmd("WinEnter", {
  group = group,
  callback = function()
    local w = vim.api.nvim_get_current_win()
    if w ~= state.win and vim.api.nvim_win_get_config(w).relative == "" then
      state.target_win = w
    end
  end,
})

vim.api.nvim_create_user_command("GitReview", function(o)
  M.open(o.args)
end, { nargs = "?", desc = "Review files changed in the last N commits (default 4)" })

vim.api.nvim_create_user_command("GitReviewOff", M.close, { desc = "Reset gitsigns base, close panel, clear marks" })

return M
