-- ==============================================================================
--  FLOATING TERMINAL  (<leader>t toggles a centered floating terminal, e.g.
--  for `scram b`/tests while working on a change)
--
--  Toggling hides the window but leaves the job running underneath - a build
--  keeps going while you go edit more, <leader>t again brings you right back
--  to the same session, not a fresh shell. Works from normal mode or from
--  inside the terminal itself (so you don't have to leave insert mode first).
-- ==============================================================================

local term_buf = nil
local term_win = nil

local function float_opts()
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.85)
  return {
    relative = "editor",
    width = width,
    height = height,
    row = math.floor((vim.o.lines - height) / 2),
    col = math.floor((vim.o.columns - width) / 2),
    style = "minimal",
    border = "rounded",
    title = " terminal ",
    title_pos = "center",
  }
end

local function toggle_terminal()
  if term_win and vim.api.nvim_win_is_valid(term_win) then
    vim.api.nvim_win_hide(term_win)
    term_win = nil
    return
  end

  if term_buf and vim.api.nvim_buf_is_valid(term_buf) then
    term_win = vim.api.nvim_open_win(term_buf, true, float_opts())
    vim.cmd("startinsert")
    return
  end

  term_buf = vim.api.nvim_create_buf(false, true)
  term_win = vim.api.nvim_open_win(term_buf, true, float_opts())
  vim.bo[term_buf].bufhidden = "hide"
  vim.fn.termopen(vim.o.shell)
  vim.cmd("startinsert")
end

vim.keymap.set({ "n", "t" }, "<leader>t", toggle_terminal, { desc = "Toggle floating terminal" })

-- keep the float centered and correctly sized if the outer window resizes
vim.api.nvim_create_autocmd("VimResized", {
  group = vim.api.nvim_create_augroup("float_term_resize", { clear = true }),
  callback = function()
    if term_win and vim.api.nvim_win_is_valid(term_win) then
      vim.api.nvim_win_set_config(term_win, float_opts())
    end
  end,
})
