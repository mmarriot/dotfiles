-- ==============================================================================
--  KEYMAPS  (ported from ~/.vimrc; LSP / git / telescope / oil maps live with
--  their plugins, and the CMSSW + terminal maps live in cmssw.vim)
-- ==============================================================================

local map = vim.keymap.set

-- -- Window navigation ---------------------------------------------------------
map("n", "<leader>a", "<C-w>h", { desc = "Window left" })
map("n", "<leader>d", "<C-w>l", { desc = "Window right" })
map("n", "<leader>s", "<C-w>j", { desc = "Window down" })
map("n", "<leader>w", "<C-w>k", { desc = "Window up" })

-- -- Window resize -------------------------------------------------------------
map("n", "<leader>=", "<C-w>=", { desc = "Equalize windows" })
map("n", "<leader>+", "<C-w>5+", { desc = "Taller" })
map("n", "<leader>-", "<C-w>5-", { desc = "Shorter" })
map("n", "<leader>>", "<C-w>5>", { desc = "Wider" })
map("n", "<leader><", "<C-w>5<", { desc = "Narrower" })

-- -- Buffer navigation ---------------------------------------------------------
map("n", "]b", "<cmd>bnext<cr>", { desc = "Next buffer" })
map("n", "[b", "<cmd>bprev<cr>", { desc = "Prev buffer" })
map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Delete buffer" })
map("n", "<leader>ba", "<cmd>bufdo bd<cr>", { desc = "Delete all buffers" })

-- -- Quickfix / error list -----------------------------------------------------
map("n", "]q", "<cmd>cnext<cr>", { desc = "Next quickfix" })
map("n", "[q", "<cmd>cprev<cr>", { desc = "Prev quickfix" })
map("n", "<leader>qo", "<cmd>copen<cr>", { desc = "Open quickfix" })
map("n", "<leader>qc", "<cmd>cclose<cr>", { desc = "Close quickfix" })

-- -- Indentation (keep visual selection after indent) --------------------------
map("n", ">", ">>", { desc = "Indent" })
map("n", "<", "<<", { desc = "Dedent" })
map("v", ">", ">gv", { desc = "Indent, keep selection" })
map("v", "<", "<gv", { desc = "Dedent, keep selection" })

-- -- Clear search highlight ----------------------------------------------------
map("n", "<leader>/", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

-- -- Close / save --------------------------------------------------------------
map("n", "<leader>es", "<cmd>q<cr>", { desc = "Quit window" })
map("n", "<leader>eq", "<cmd>bd<cr>", { desc = "Delete buffer" })
map("n", "<leader>x", "<cmd>w<cr>", { desc = "Save" })

-- -- Gems from jonhoo: always center search results --------------------------
map("n", "n", "nzz", { silent = true })
map("n", "N", "Nzz", { silent = true })
map("n", "*", "*zz", { silent = true })
map("n", "#", "#zz", { silent = true })

-- -- Highlight yanked text briefly --------------------------------------------
vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("highlight_yank", { clear = true }),
  callback = function()
    vim.highlight.on_yank({ timeout = 200 })
  end,
})
