-- ==============================================================================
--  EDITOR  (kept from your vimrc: illuminate, commentary, surround, auto-pairs,
--  markdown) + jonhoo's nav gems (leap, lsp_signature)
-- ==============================================================================

return {
  -- highlight other uses of the word under the cursor
  {
    "RRethy/vim-illuminate",
    event = { "BufReadPost", "BufNewFile" },
    config = function()
      require("illuminate").configure({ delay = 200 })
    end,
  },

  -- gc / gcc to comment (same muscle memory as your vimrc)
  { "tpope/vim-commentary", event = "VeryLazy" },

  -- cs"' / ds( / ysiw) to change/delete/add surroundings
  { "tpope/vim-surround", event = "VeryLazy" },

  -- auto-close brackets/quotes; keep your space-padding fix
  {
    "jiangmiao/auto-pairs",
    event = "InsertEnter",
    init = function()
      vim.g.AutoPairsMapSpace = 0
      vim.g.AutoPairsMultilineClose = 0
      -- Its <CR> remap tries to read maparg('<CR>','i',0,1).rhs to wrap
      -- around whatever else owns <CR> - but nvim-cmp's confirm mapping is a
      -- Lua callback, not a string rhs, so that key doesn't exist and it
      -- throws E716 (then E121/E116 as fallout) on every fresh buffer.
      -- Turning off just this remap keeps bracket/quote auto-closing intact;
      -- <CR> confirm still comes from nvim-cmp either way.
      vim.g.AutoPairsMapCR = 0
    end,
  },

  -- markdown (your settings)
  {
    "preservim/vim-markdown",
    ft = "markdown",
    init = function()
      vim.g.vim_markdown_folding_disabled = 1
      vim.g.vim_markdown_conceal = 0
      vim.g.vim_markdown_conceal_code_blocks = 0
      vim.g.vim_markdown_new_list_item_indent = 0
      vim.g.vim_markdown_auto_insert_bullets = 1
      vim.g.vim_markdown_frontmatter = 1
    end,
  },

  -- leap: jump anywhere with s + 2 chars (jonhoo). Repo moved to Codeberg.
  {
    url = "https://codeberg.org/andyg/leap.nvim",
    event = "VeryLazy",
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap)")
      vim.keymap.set("n", "S", "<Plug>(leap-from-window)")
    end,
  },

  -- function signature popup while typing arguments (jonhoo)
  {
    "ray-x/lsp_signature.nvim",
    event = "VeryLazy",
    opts = {
      doc_lines = 0,
      handler_opts = { border = "none" },
    },
  },
}
