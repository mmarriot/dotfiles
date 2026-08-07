-- ==============================================================================
--  TREESITTER  (better syntax highlighting, indent, textobjects)
--  Pinned to the stable `master` branch API. Parsers compile with the system
--  cc (gcc 8.5 is fine); no external download of prebuilt binaries.
--
--  NOTE: the `master` branch supports Neovim 0.10/0.11 only - it is NOT
--  compatible with 0.12 (its highlighter crashes on every redraw there). This
--  box therefore runs Neovim 0.11 (see ~/.local/bin/nvim -> ~/opt/nvim-0.11).
-- ==============================================================================

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "master",
  event = { "BufReadPre", "BufNewFile" },
  build = ":TSUpdate",
  config = function()
    require("nvim-treesitter.configs").setup({
      ensure_installed = {
        "c", "cpp", "cuda", "cmake", "python", "lua", "vim", "vimdoc",
        "bash", "markdown", "markdown_inline", "json", "yaml", "rust",
        "comment", "query", "gitignore", "diff",
      },
      sync_install = false,
      auto_install = false,
      highlight = {
        enable = true,
        additional_vim_regex_highlighting = false,
      },
      indent = { enable = true },
      incremental_selection = {
        enable = true,
        keymaps = {
          init_selection = "<C-space>",
          node_incremental = "<C-space>",
          node_decremental = "<bs>",
          scope_incremental = false,
        },
      },
    })
  end,
}
