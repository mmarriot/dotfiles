-- ==============================================================================
--  WORKTREE PORT VIEW
--
--  For the workflow "someone else's worktree has changes I want in my src" -
--  browse their files, copy what you want across, by hand, as plain editing.
--  Nothing here ever writes to git: no `git add`, no index, no stash, no
--  merge. Files are read out of their tree with `git show`; your side is a
--  normal buffer on a normal file that `:w` writes normally.
--
--  :Wt / <leader>gt   pick which worktree to port FROM
--  <leader>dc          port view, listing every file their branch touched
--  <leader>dh          port view, starting on their branch's commits - <CR>
--                       on one narrows the file list to just its files,
--                       <Tab> marks several first
--  <leader>dw          quick two-pane diff of just the CURRENT file against
--                       its counterpart on the other side (bidirectional,
--                       and reads working-tree files, so it includes their
--                       uncommitted WIP); <leader>dq closes it
--  <leader>dq          close the port view / turn dw's diff off
--
--  ---- what "their branch touched" means -------------------------------------
--  Worktrees are usually checked out on a NEWER upstream than your branch, so
--  a plain HEAD..theirs is mostly upstream drift: on this repo that's 258
--  commits and 5117 files, of which ~51 and ~126 are actually theirs. So the
--  scope is their TOPIC range instead - walk first-parent from their head and
--  stop at the first merge commit, since upstream history is a wall of "Merge
--  pull request #NNN" and topic work is the linear stack sitting on top of it.
--  Falls back to merge-base if their history has no merges at all.
--
--  ---- the file list is FIXED ------------------------------------------------
--  The list is computed once from those commits and does not change while you
--  work. This is the whole point: a git-diff-driven panel drops a file the
--  moment you make it match, which is exactly when you've just finished
--  porting it and might still want it. Here the entry stays and its status
--  flips to done. Statuses (recomputed on every :w, by blob hash, never via
--  the index):
--    = you have it and it matches theirs - done
--    ~ you have it and it differs - still to port
--    + they have it, you don't - nothing on your side yet
--    - you have it, they don't - they deleted or never had it
--
--  ---- in the sidebar --------------------------------------------------------
--    <CR>   open the file (or, on a commit, narrow the list to it)
--    <Tab>  mark/unmark a commit; <CR> then opens the union of the marked ones
--    <BS>   back to the commit list
--    f      filter the list by a substring ("TICL", ".h", ...); empty clears
--    R      recompute statuses
--    q      close the port view
--
--  ---- in the two diff panes -------------------------------------------------
--  Left is THEIRS, readonly. Right is YOUR REAL FILE, editable and writable.
--    <leader>o   pull the hunk under the cursor into your file - works from
--                 EITHER pane, so you needn't think about which side you're
--                 standing in (plain `do` errors from the readonly side)
--    <leader>O   take their whole file, in one go - this is how you "copy it
--                 over", including for a file you don't have yet: the right
--                 pane is just an empty buffer at the right path, so <leader>O
--                 then :w creates it (parent dirs included). It stays in the
--                 list afterwards.
--    <C-n>/<C-p> next / previous file, without going back to the sidebar
--    ]c / [c     next / previous hunk (built in)
--    :w          writes the file. That is all it does.
-- ==============================================================================

-- ---------------------------------------------------------------------------
-- colours - deliberately quiet. Gruvbox's stock DiffText is #fabd2f (its
-- brightest yellow) on every changed span, which is unreadable when you're
-- staring at diffs all day; these are washes you can read code through.
-- Re-applied on ColorScheme so a colorscheme reload doesn't undo them.
-- ---------------------------------------------------------------------------
local function set_highlights()
  local hl = function(name, val) vim.api.nvim_set_hl(0, name, val) end
  hl("DiffAdd", { bg = "#26332a" })
  hl("DiffChange", { bg = "#2b3038" })
  hl("DiffText", { bg = "#3f4a5c" })
  hl("DiffDelete", { bg = "#2a2426", fg = "#4a4045" })

  hl("WtPortHeader", { fg = "#83a598", bold = true })
  hl("WtPortHint", { fg = "#7c6f64", italic = true })
  hl("WtPortGroup", { fg = "#d5c4a1", bold = true })
  hl("WtPortSame", { fg = "#5a6c50" })
  hl("WtPortDiff", { fg = "#83a598" })
  hl("WtPortNew", { fg = "#b8bb26" })
  hl("WtPortGone", { fg = "#9d6b6b" })
  hl("WtPortDim", { fg = "#665c54" })
  hl("WtPortMark", { fg = "#fe8019", bold = true })
end
set_highlights()
vim.api.nvim_create_autocmd("ColorScheme", { callback = set_highlights })

-- linematch makes vimdiff align changed lines within a hunk instead of
-- showing a block-replace, which is most of what makes a diff readable
pcall(function() vim.opt.diffopt:append("linematch:60") end)

-- ---------------------------------------------------------------------------
-- git plumbing. Every call runs against the MAIN worktree: worktrees share an
-- object database, so their commits and blobs are all readable from here.
-- ---------------------------------------------------------------------------
local function git(dir, args)
  local cmd = { "git", "-C", dir }
  vim.list_extend(cmd, args)
  local out = vim.fn.systemlist(cmd)
  return out, vim.v.shell_error == 0
end

local S = {
  src = nil, -- main worktree, absolute
  wt = nil, -- { path, label, head, base, ncommits }
  mode = "files", -- "files" | "commits"
  entries = {}, -- { { path, status, sha } }
  commits = {}, -- { { sha, subject, author, marked } }
  scope = nil, -- human label for what the file list is scoped to
  filter = nil,
  tabpage = nil,
  side_win = nil,
  side_buf = nil,
  theirs_win = nil,
  mine_win = nil,
  cur = nil, -- index into S.entries currently open
  line_map = {}, -- sidebar line -> index into entries/commits
}

local ns = vim.api.nvim_create_namespace("wtport")

local function warn(msg) vim.notify(msg, vim.log.levels.WARN) end

-- every worktree of this repo; the first is always the main one
local function worktrees()
  local lines = git(vim.fn.getcwd(), { "worktree", "list", "--porcelain" })
  local trees, cur = {}, nil
  for _, line in ipairs(lines) do
    local path = line:match("^worktree (.+)$")
    if path then
      cur = { path = path, name = vim.fn.fnamemodify(path, ":t") }
      table.insert(trees, cur)
    elseif cur and not cur.label then
      local branch = line:match("^branch (.+)$")
      if branch then
        cur.label = cur.name .. "  [" .. branch:gsub("^refs/heads/", "") .. "]"
      elseif line == "detached" then
        cur.label = cur.name .. "  [detached]"
      end
    end
  end
  return trees
end

local function src_root()
  if S.src then return S.src end
  local trees = worktrees()
  if #trees == 0 then
    warn("Not inside a git repo")
    return nil
  end
  S.src = trees[1].path
  return S.src
end

-- Their topic range: walk first-parent until the first merge commit. Upstream
-- history is merge commits ("Merge pull request #NNN"), topic work is the
-- linear stack above the newest one, so that merge is the base to diff from.
-- Bounded at 500 - no topic branch is longer, and CMSSW's full first-parent
-- history is ~100k commits we'd otherwise read for nothing.
local function topic_base(src, head)
  local out = git(src, { "log", "--format=%H %P", "--first-parent", "-n", "500", head })
  for _, line in ipairs(out) do
    local sha, parents = line:match("^(%S+)%s*(.*)$")
    local n = 0
    for _ in (parents or ""):gmatch("%S+") do n = n + 1 end
    if n > 1 then return sha end
  end
  -- no merge in reach: fall back to where their history and yours diverged
  local mb = git(src, { "merge-base", "HEAD", head })[1]
  if mb and mb ~= "" then return mb end
  warn("Could not find a base commit for " .. head:sub(1, 11))
  return nil
end

local function resolve_worktree(t)
  local src = src_root()
  if not src then return nil end
  local head = git(t.path, { "rev-parse", "HEAD" })[1]
  if not head or head == "" then
    warn("Could not resolve HEAD of " .. t.path)
    return nil
  end
  local base = topic_base(src, head)
  if not base then return nil end
  local n = tonumber(git(src, { "rev-list", "--count", base .. ".." .. head })[1]) or 0
  return { path = t.path, label = t.label or t.name, head = head, base = base, ncommits = n }
end

local function pick_worktree(on_done)
  local src = src_root()
  if not src then return end
  local choices = {}
  for _, t in ipairs(worktrees()) do
    if t.path ~= src then table.insert(choices, t) end
  end
  if #choices == 0 then
    warn("No other git worktrees found")
    return
  end
  local function use(choice)
    local wt = resolve_worktree(choice)
    if not wt then return end
    S.wt = wt
    vim.notify(("Porting from %s  (%d commits)"):format(wt.label, wt.ncommits))
    if on_done then on_done() end
  end
  if #choices == 1 then return use(choices[1]) end
  vim.ui.select(choices, {
    prompt = "Port from worktree:",
    format_item = function(t) return t.label or t.path end,
  }, function(choice)
    if choice then use(choice) end
  end)
end

local function with_worktree(fn)
  if S.wt then fn() else pick_worktree(fn) end
end

-- ---------------------------------------------------------------------------
-- what they changed
-- ---------------------------------------------------------------------------

-- \x1f (unit separator) rather than the more usual \x00: Vim's system()
-- represents NUL as a newline internally, so a %x00-separated format comes
-- back out of systemlist() split across three lines per commit
local function commits_in_range(src, base, head)
  local out = git(src, { "log", "--format=%h%x1f%an%x1f%s", base .. ".." .. head })
  local commits = {}
  for _, line in ipairs(out) do
    local sha, author, subject = line:match("^([^\31]*)\31([^\31]*)\31(.*)$")
    if sha then
      table.insert(commits, { sha = sha, author = author, subject = subject })
    end
  end
  return commits
end

local function files_in_range(src, base, head)
  local paths, seen = {}, {}
  for _, line in ipairs(git(src, { "diff", "--name-only", base .. ".." .. head })) do
    if line ~= "" and not seen[line] then
      seen[line] = true
      table.insert(paths, line)
    end
  end
  return paths
end

local function files_in_commits(src, shas)
  local paths, seen = {}, {}
  for _, sha in ipairs(shas) do
    for _, line in ipairs(git(src, { "show", "--pretty=format:", "--name-only", sha })) do
      if line ~= "" and not seen[line] then
        seen[line] = true
        table.insert(paths, line)
      end
    end
  end
  return paths
end

-- Status by blob hash, comparing THEIR tree to YOUR FILES ON DISK.
--
-- Deliberately not `git diff <rev>`: that goes through your index, so a file
-- you copied across but never staged reads as "deleted" however right its
-- content is - which is what used to make this need a `git add` to stay
-- honest. `ls-tree` reads their blob ids and `hash-object` hashes your files
-- directly; neither one touches the index, and both are exact.
local function refresh_status()
  local src = src_root()
  if not src or not S.wt or #S.entries == 0 then return end

  local paths = {}
  for _, e in ipairs(S.entries) do table.insert(paths, e.path) end

  local theirs = {}
  local args = { "ls-tree", "-r", S.wt.head, "--" }
  vim.list_extend(args, paths)
  for _, line in ipairs(git(src, args)) do
    local sha, path = line:match("^%d+%s+blob%s+(%x+)\t(.*)$")
    if sha then theirs[path] = sha end
  end

  local on_disk, disk_paths = {}, {}
  for _, e in ipairs(S.entries) do
    if vim.fn.filereadable(src .. "/" .. e.path) == 1 then
      table.insert(disk_paths, src .. "/" .. e.path)
      table.insert(on_disk, e.path)
    end
  end
  local mine = {}
  if #disk_paths > 0 then
    local hargs = { "hash-object" }
    vim.list_extend(hargs, disk_paths)
    local hashes = git(src, hargs)
    for i, path in ipairs(on_disk) do mine[path] = hashes[i] end
  end

  for _, e in ipairs(S.entries) do
    e.sha = theirs[e.path]
    if not e.sha then
      e.status = "gone"
    elseif not mine[e.path] then
      e.status = "new"
    elseif mine[e.path] == e.sha then
      e.status = "same"
    else
      e.status = "diff"
    end
  end
end

-- ---------------------------------------------------------------------------
-- sidebar
-- ---------------------------------------------------------------------------

local GLYPH = {
  same = { "=", "WtPortSame" },
  diff = { "~", "WtPortDiff" },
  new = { "+", "WtPortNew" },
  gone = { "-", "WtPortGone" },
}

local SIDE_WIDTH = 54

-- headers, subjects: the front carries the meaning, so drop the tail
local function trunc_tail(s, width)
  if vim.fn.strdisplaywidth(s) <= width then return s end
  return s:sub(1, width - 1) .. "\u{2026}"
end

-- paths: the BASENAME carries the meaning, so drop the front instead
local function trunc_head(s, width)
  if vim.fn.strdisplaywidth(s) <= width then return s end
  return "\u{2026}" .. s:sub(-(width - 1))
end

-- CMSSW paths are Package/Subpackage/..., so grouping on the first two
-- components turns a flat 126-line list into something you can skim
local function group_of(path)
  local a, b = path:match("^([^/]+)/([^/]+)/")
  if a and b then return a .. "/" .. b end
  return path:match("^([^/]+)/") or "."
end

-- always {idx into S.entries, entry}, so the filtered and unfiltered cases
-- render through exactly the same path
local function visible_entries()
  local needle = (S.filter or ""):lower()
  local out = {}
  for i, e in ipairs(S.entries) do
    if needle == "" or e.path:lower():find(needle, 1, true) then
      out[#out + 1] = { idx = i, e = e }
    end
  end
  return out
end

local function render()
  if not (S.side_buf and vim.api.nvim_buf_is_valid(S.side_buf)) then return end
  local lines, marks = {}, {}
  S.line_map = {}

  local function add(text, hls)
    lines[#lines + 1] = text
    for _, h in ipairs(hls or {}) do
      marks[#marks + 1] = { #lines - 1, h[1], h[2], h[3] }
    end
  end

  local title = S.wt and S.wt.label or "(no worktree)"
  add(" " .. trunc_tail(title, SIDE_WIDTH - 2), { { 0, -1, "WtPortHeader" } })

  if S.mode == "commits" then
    local n = 0
    for _, c in ipairs(S.commits) do if c.marked then n = n + 1 end end
    add(" " .. #S.commits .. " commits" .. (n > 0 and ("  -  " .. n .. " marked") or ""),
      { { 0, -1, "WtPortDim" } })
    add(" <CR> files   <Tab> mark   q close", { { 0, -1, "WtPortHint" } })
    add(string.rep("-", SIDE_WIDTH - 1), { { 0, -1, "WtPortDim" } })
    for i, c in ipairs(S.commits) do
      local mark = c.marked and "*" or " "
      local head = (" %s %s "):format(mark, c.sha)
      add(head .. trunc_tail(c.subject, SIDE_WIDTH - 1 - #head), {
        { 1, 2, "WtPortMark" },
        { 3, 3 + #c.sha, "WtPortDim" },
      })
      S.line_map[#lines] = i
    end
  else
    local counts = { same = 0, diff = 0, new = 0, gone = 0 }
    for _, e in ipairs(S.entries) do counts[e.status or "diff"] = (counts[e.status or "diff"] or 0) + 1 end
    add((" %d done   %d to port   %d new   %d theirs-only")
      :format(counts.same, counts.diff, counts.new, counts.gone), { { 0, -1, "WtPortDim" } })
    add(" " .. trunc_tail((S.scope or "all their changes")
      .. (S.filter and ("   /" .. S.filter) or ""), SIDE_WIDTH - 2), { { 0, -1, "WtPortHint" } })
    add(" <CR> open   f filter   R refresh   <BS> commits", { { 0, -1, "WtPortHint" } })
    add(string.rep("-", SIDE_WIDTH - 1), { { 0, -1, "WtPortDim" } })

    local list = visible_entries()
    local group = nil
    for _, item in ipairs(list) do
      local idx, e = item.idx, item.e
      local g = group_of(e.path)
      if g ~= group then
        group = g
        add(" " .. trunc_tail(g, SIDE_WIDTH - 2), { { 0, -1, "WtPortGroup" } })
      end
      local glyph = GLYPH[e.status or "diff"]
      local rest = trunc_head(e.path:sub(#group + 2), SIDE_WIDTH - 5)
      local hls = { { 2, 3, glyph[2] } }
      if idx == S.cur then hls[#hls + 1] = { 4, -1, "WtPortMark" } end
      add(("  %s %s"):format(glyph[1], rest), hls)
      S.line_map[#lines] = idx
    end
    if #list == 0 then
      add("  (nothing matches)", { { 0, -1, "WtPortDim" } })
    end
  end

  vim.bo[S.side_buf].modifiable = true
  vim.api.nvim_buf_set_lines(S.side_buf, 0, -1, false, lines)
  vim.bo[S.side_buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(S.side_buf, ns, 0, -1)
  for _, m in ipairs(marks) do
    pcall(vim.api.nvim_buf_set_extmark, S.side_buf, ns, m[1], m[2], {
      end_col = m[3] < 0 and #(lines[m[1] + 1]) or math.min(m[3], #(lines[m[1] + 1])),
      hl_group = m[4],
    })
  end
end

local function item_at_cursor()
  if not (S.side_win and vim.api.nvim_win_is_valid(S.side_win)) then return nil end
  local lnum = vim.api.nvim_win_get_cursor(S.side_win)[1]
  return S.line_map[lnum]
end

-- ---------------------------------------------------------------------------
-- the two diff panes
-- ---------------------------------------------------------------------------

local function their_lines(path)
  local src = src_root()
  local out, ok = git(src, { "show", S.wt.head .. ":" .. path })
  if not ok then return {} end
  return out
end

local function ensure_panes()
  if S.theirs_win and vim.api.nvim_win_is_valid(S.theirs_win)
      and S.mine_win and vim.api.nvim_win_is_valid(S.mine_win) then
    return true
  end
  if not (S.side_win and vim.api.nvim_win_is_valid(S.side_win)) then return false end
  vim.api.nvim_set_current_win(S.side_win)
  vim.cmd("rightbelow vsplit")
  S.theirs_win = vim.api.nvim_get_current_win()
  vim.cmd("rightbelow vsplit")
  S.mine_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_width(S.side_win, SIDE_WIDTH)
  return true
end

local open_entry -- forward declaration, used by the pane keymaps

local function pane_keymaps(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc, silent = true })
  end
  -- `do` only works from the modifiable side and errors ("E21: 'modifiable'
  -- is off") from the readonly one, which is often the side you're reading -
  -- so hop to the editable pane first. Diff panes are line-aligned, so the
  -- hunk under your cursor is the hunk under its cursor.
  map("<leader>o", function()
    if not (S.mine_win and vim.api.nvim_win_is_valid(S.mine_win)) then return end
    vim.api.nvim_set_current_win(S.mine_win)
    vim.cmd("normal! do")
  end, "Pull this hunk into my file")

  map("<leader>O", function()
    if not (S.mine_win and S.theirs_win) then return end
    local from = vim.api.nvim_win_get_buf(S.theirs_win)
    local to = vim.api.nvim_win_get_buf(S.mine_win)
    -- set the lines outright rather than :%diffget, which has nothing to act
    -- on when your side is an empty buffer for a file you don't have yet -
    -- the exact case where "just copy theirs over" matters most
    vim.api.nvim_buf_set_lines(to, 0, -1, false, vim.api.nvim_buf_get_lines(from, 0, -1, false))
    vim.api.nvim_set_current_win(S.mine_win)
    vim.cmd("diffupdate")
  end, "Take their whole file")

  map("<C-n>", function() if S.cur then open_entry(S.cur + 1) end end, "Next file")
  map("<C-p>", function() if S.cur then open_entry(S.cur - 1) end end, "Previous file")
end

open_entry = function(idx)
  local e = S.entries[idx]
  if not e then return end
  if not ensure_panes() then return end
  local src = src_root()
  S.cur = idx

  -- theirs: a throwaway scratch buffer, wiped when it leaves the window
  local tbuf = vim.api.nvim_create_buf(false, true)
  local content = e.status == "gone" and {} or their_lines(e.path)
  vim.api.nvim_buf_set_lines(tbuf, 0, -1, false, content)
  vim.bo[tbuf].modifiable = false
  vim.bo[tbuf].bufhidden = "wipe"
  vim.bo[tbuf].buftype = "nofile"
  vim.bo[tbuf].swapfile = false
  local ft = vim.filetype.match({ filename = e.path, contents = content })
  if ft then vim.bo[tbuf].filetype = ft end
  vim.api.nvim_win_set_buf(S.theirs_win, tbuf)

  -- mine: the real file, a real buffer, editable and writable
  local abs = src .. "/" .. e.path
  vim.api.nvim_win_call(S.mine_win, function()
    vim.cmd("keepalt edit " .. vim.fn.fnameescape(abs))
  end)
  local mbuf = vim.api.nvim_win_get_buf(S.mine_win)

  -- :w on a file you don't have yet needs its parent dirs. This is the only
  -- filesystem side effect in here, and it is mkdir -p, not git.
  vim.api.nvim_create_autocmd("BufWritePre", {
    buffer = mbuf,
    callback = function()
      vim.fn.mkdir(vim.fn.fnamemodify(abs, ":h"), "p")
    end,
  })
  vim.api.nvim_create_autocmd("BufWritePost", {
    buffer = mbuf,
    callback = function()
      refresh_status()
      render()
    end,
  })

  for _, win in ipairs({ S.theirs_win, S.mine_win }) do
    vim.api.nvim_win_call(win, function() vim.cmd("diffthis") end)
    vim.wo[win].foldenable = false
    vim.wo[win].wrap = false
  end
  vim.wo[S.theirs_win].winbar = "%#WtPortDim#THEIRS  " .. S.wt.label .. "  (readonly)"
  vim.wo[S.mine_win].winbar = "%#WtPortHeader#MINE  " .. e.path
  vim.api.nvim_win_call(S.mine_win, function() vim.cmd("diffupdate") end)

  pane_keymaps(tbuf)
  pane_keymaps(mbuf)
  vim.api.nvim_set_current_win(S.mine_win)
  render()
end

-- ---------------------------------------------------------------------------
-- view lifecycle
-- ---------------------------------------------------------------------------

local function close_view()
  if S.tabpage and vim.api.nvim_tabpage_is_valid(S.tabpage) then
    if #vim.api.nvim_list_tabpages() > 1 then
      vim.api.nvim_set_current_tabpage(S.tabpage)
      vim.cmd("tabclose")
    else
      vim.cmd("diffoff!")
      vim.cmd("only")
    end
  end
  S.tabpage, S.side_win, S.side_buf, S.theirs_win, S.mine_win, S.cur = nil, nil, nil, nil, nil, nil
end

local function set_files(paths, scope)
  S.entries = {}
  table.sort(paths)
  for _, p in ipairs(paths) do table.insert(S.entries, { path = p, status = "diff" }) end
  S.scope = scope
  S.mode = "files"
  S.filter = nil
  S.cur = nil
  refresh_status()
end

local function sidebar_keymaps(buf)
  local function map(lhs, fn, desc)
    vim.keymap.set("n", lhs, fn, { buffer = buf, desc = desc, silent = true, nowait = true })
  end

  map("<CR>", function()
    local i = item_at_cursor()
    if not i then return end
    if S.mode == "commits" then
      local chosen = {}
      for _, c in ipairs(S.commits) do if c.marked then table.insert(chosen, c.sha) end end
      local scope
      if #chosen == 0 then
        local c = S.commits[i]
        chosen = { c.sha }
        scope = ("%s  %s  (%s)"):format(c.sha, c.subject, c.author)
      else
        scope = #chosen .. " marked commits"
      end
      set_files(files_in_commits(src_root(), chosen), scope)
      render()
    else
      open_entry(i)
    end
  end, "Open / narrow")

  map("<Tab>", function()
    if S.mode ~= "commits" then return end
    local i = item_at_cursor()
    if not i then return end
    S.commits[i].marked = not S.commits[i].marked
    local pos = vim.api.nvim_win_get_cursor(S.side_win)
    render()
    pcall(vim.api.nvim_win_set_cursor, S.side_win, { pos[1] + 1, pos[2] })
  end, "Mark commit")

  map("<BS>", function()
    if not S.wt then return end
    S.commits = commits_in_range(src_root(), S.wt.base, S.wt.head)
    S.mode = "commits"
    render()
  end, "Back to commits")

  map("f", function()
    vim.ui.input({ prompt = "Filter files: ", default = S.filter or "" }, function(input)
      S.filter = (input and input ~= "") and input or nil
      render()
    end)
  end, "Filter")

  map("R", function()
    refresh_status()
    render()
  end, "Refresh statuses")

  map("q", close_view, "Close port view")
  map("?", function()
    vim.notify("<CR> open  <Tab> mark commit  <BS> commits  f filter  R refresh  q close\n"
      .. "in the diff: <leader>o hunk  <leader>O whole file  <C-n>/<C-p> next/prev")
  end, "Help")
end

local function open_view(mode)
  local src = src_root()
  if not src then return end
  close_view()

  vim.cmd("tabnew")
  S.tabpage = vim.api.nvim_get_current_tabpage()
  S.side_buf = vim.api.nvim_create_buf(false, true)
  S.side_win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(S.side_win, S.side_buf)

  vim.bo[S.side_buf].buftype = "nofile"
  vim.bo[S.side_buf].bufhidden = "wipe"
  vim.bo[S.side_buf].swapfile = false
  vim.bo[S.side_buf].filetype = "wtport"
  vim.bo[S.side_buf].modifiable = false
  local w = S.side_win
  vim.wo[w].number = false
  vim.wo[w].relativenumber = false
  vim.wo[w].wrap = false
  vim.wo[w].cursorline = true
  vim.wo[w].signcolumn = "no"
  vim.wo[w].foldcolumn = "0"
  vim.wo[w].winfixwidth = true
  vim.wo[w].list = false
  vim.api.nvim_win_set_width(w, SIDE_WIDTH)

  sidebar_keymaps(S.side_buf)

  if mode == "commits" then
    S.commits = commits_in_range(src, S.wt.base, S.wt.head)
    S.mode = "commits"
    if #S.commits == 0 then warn("No commits unique to " .. S.wt.label) end
  else
    set_files(files_in_range(src, S.wt.base, S.wt.head), "all their changes")
    if #S.entries == 0 then warn("No files changed in " .. S.wt.label) end
  end
  render()
end

-- ---------------------------------------------------------------------------
-- dw: quick one-file diff against the counterpart on the other side. Reads
-- files on disk rather than a git ref, so it picks up their uncommitted WIP.
-- Bidirectional: from your src it needs a worktree picked; from inside a
-- worktree the target is unambiguously your src, so it just goes.
-- ---------------------------------------------------------------------------
local dw_win = nil

local function counterpart_path()
  local src = src_root()
  if not src then return nil end
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    warn("No file in the current buffer")
    return nil
  end
  if file:sub(1, #src + 1) == src .. "/" then
    if not S.wt then return nil end
    return S.wt.path .. file:sub(#src + 1)
  end
  for _, t in ipairs(worktrees()) do
    if t.path ~= src and file:sub(1, #t.path + 1) == t.path .. "/" then
      return src .. file:sub(#t.path + 1)
    end
  end
  warn("Buffer is not under your src root or a known worktree")
  return nil
end

local function dw_open()
  local target = counterpart_path()
  if not target then return end
  if vim.fn.filereadable(target) == 0 then
    warn("No counterpart file: " .. target)
    return
  end
  vim.cmd("diffthis")
  vim.cmd("rightbelow vsplit " .. vim.fn.fnameescape(target))
  vim.cmd("diffthis")
  dw_win = vim.api.nvim_get_current_win()
end

local function dw_entry()
  local src = src_root()
  local file = vim.api.nvim_buf_get_name(0)
  if src and file:sub(1, #src + 1) == src .. "/" then
    with_worktree(dw_open)
  else
    dw_open()
  end
end

local function dq()
  if S.tabpage and vim.api.nvim_get_current_tabpage() == S.tabpage then
    return close_view()
  end
  vim.cmd("diffoff!")
  if dw_win and vim.api.nvim_win_is_valid(dw_win) then
    vim.api.nvim_win_close(dw_win, false)
  end
  dw_win = nil
end

-- ---------------------------------------------------------------------------
vim.api.nvim_create_user_command("Wt", function() pick_worktree() end,
  { desc = "Pick the worktree to port from" })

local map = vim.keymap.set
map("n", "<leader>gt", function() pick_worktree() end, { desc = "Pick worktree to port from" })
map("n", "<leader>dc", function() with_worktree(function() open_view("files") end) end,
  { desc = "Port view: their changed files" })
map("n", "<leader>dh", function() with_worktree(function() open_view("commits") end) end,
  { desc = "Port view: their commits" })
map("n", "<leader>dw", dw_entry, { desc = "Diff this file vs its counterpart" })
map("n", "<leader>dq", dq, { desc = "Close port view / diff off" })
