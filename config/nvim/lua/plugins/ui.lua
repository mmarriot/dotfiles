-- ==============================================================================
--  UI  (statusline, keybinding hints, symbol outline, diagnostics list)
-- ==============================================================================

return {
  -- statusline (branch, file, diagnostics, filetype, position)
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        theme = "gruvbox",
        globalstatus = true,
        section_separators = "",
        component_separators = "",
      },
      sections = {
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "filetype" },
      },
    },
  },

  -- shows available leader mappings as you type - great while learning nvim
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    opts = {},
  },

  -- symbol outline: jump between functions/classes in big CMSSW files
  {
    "stevearc/aerial.nvim",
    -- master requires Neovim 0.12+; this box runs 0.11, so pin the compat branch
    branch = "nvim-0.11",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    cmd = "AerialToggle",
    opts = {},
    keys = {
      { "<leader>i", "<cmd>AerialToggle!<cr>", desc = "Symbol outline (aerial)" },
    },
  },

  -- project-wide diagnostics list (step through every clang error)
  {
    "folke/trouble.nvim",
    cmd = "Trouble",
    keys = {
      { "<leader>ce", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      { "<leader>cq", "<cmd>Trouble qflist toggle<cr>", desc = "Quickfix (Trouble)" },
    },
    opts = {},
  },
}
