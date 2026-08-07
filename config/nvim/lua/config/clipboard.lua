-- ==============================================================================
--  CLIPBOARD  (OSC52 - Mac clipboard over plain ssh, no X server)
--
--  Mirrors the old vim-oscyank setup: every yank/delete of the unnamed, + or *
--  register is pushed to the Mac's system clipboard via an OSC52 escape. tmux
--  forwards it automatically (set-clipboard on). Paste stays local to nvim
--  (OSC52 read is unreliable/insecure), exactly as before. Uses neovim's
--  built-in OSC52 provider - no external tool.
-- ==============================================================================

local ok, osc52 = pcall(require, "vim.ui.clipboard.osc52")
if not ok then
  return
end

local send = osc52.copy("+") -- returns fn(lines) that emits the OSC52 sequence
local regs = { [""] = true, ["+"] = true, ["*"] = true }
local ops = { y = true, d = true }

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("osc52_yank", { clear = true }),
  callback = function()
    local ev = vim.v.event
    if regs[ev.regname] and ops[ev.operator] then
      local reg = ev.regname == "" and '"' or ev.regname
      send(vim.split(vim.fn.getreg(reg), "\n"))
    end
  end,
})
