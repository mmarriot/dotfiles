-- ==============================================================================
--  OIL  (file explorer - edit the filesystem like a normal buffer)
--    -           open the parent directory of the current file
--    <leader>e   open the explorer
--  Inside oil: edit lines to create/rename/delete, :w to apply, - to go up, <CR> open.
-- ==============================================================================

return {
  "stevearc/oil.nvim",
  dependencies = { "nvim-tree/nvim-web-devicons" },
  lazy = false, -- so it can take over as the default file explorer (replaces netrw)
  opts = {
    default_file_explorer = true,
    view_options = { show_hidden = true },
    keymaps = {
      ["<C-h>"] = false, -- keep C-h/j/k/l for vim-tmux-navigator
      ["<C-l>"] = false,
    },
  },
  keys = {
    { "-", "<cmd>Oil<cr>", desc = "Open parent dir (oil)" },
    { "<leader>e", "<cmd>Oil<cr>", desc = "File explorer (oil)" },
  },
}
