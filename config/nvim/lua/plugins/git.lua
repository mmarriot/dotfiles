-- ==============================================================================
--  GIT  (fugitive + gitsigns + diffview)  - your vimrc git vocabulary
--
--  Porting changes across worktrees lives in config/worktree.lua, not here -
--  it used to drive diffview through a pile of hooks (git add on every :w, a
--  full view reopen to unstick stale entries) and now does not need any of
--  them. diffview is back to being plain diffview.
-- ==============================================================================


return {
  -- Full git workflow (:Git status, diff, blame, log, merge)
  {
    "tpope/vim-fugitive",
    cmd = { "Git", "Gdiffsplit", "Gwrite", "Gclog", "G" },
    keys = {
      { "<leader>gs", "<cmd>Git<cr>", desc = "Git status" },
      { "<leader>gd", "<cmd>Gdiffsplit<cr>", desc = "Git diff split" },
      { "<leader>gb", "<cmd>Git blame<cr>", desc = "Git blame" },
      { "<leader>gl", "<cmd>0Gclog<cr>", desc = "File log" },
      { "<leader>gL", "<cmd>Git log --oneline --graph --all<cr>", desc = "Repo log graph" },
      { "<leader>gp", "<cmd>Git push<cr>", desc = "Git push" },
      { "<leader>gP", "<cmd>Git pull<cr>", desc = "Git pull" },
      { "<leader>gc", "<cmd>Git commit<cr>", desc = "Git commit" },
      { "<leader>gw", "<cmd>Gwrite<cr>", desc = "Git add (write)" },
      -- merge-conflict 3-way
      { "<leader>gm", "<cmd>Gdiffsplit!<cr>", desc = "Merge conflict diff" },
      { "<leader>gh", "<cmd>diffget //2<cr>", desc = "Take LEFT (ours)" },
      { "<leader>gr", "<cmd>diffget //3<cr>", desc = "Take RIGHT (theirs)" },
      -- lazygit in a terminal split (installed via install.sh)
      { "<leader>lg", "<cmd>below terminal lazygit<cr>", desc = "lazygit" },
    },
  },

  -- Per-line diff signs + hunk staging (replaces vim-gitgutter)
  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "-" },
        topdelete = { text = "-" },
        changedelete = { text = "~" },
      },
      on_attach = function(bufnr)
        local gs = require("gitsigns")
        local function map(l, r, desc)
          vim.keymap.set("n", l, r, { buffer = bufnr, desc = desc })
        end
        map("]h", function() gs.nav_hunk("next") end, "Next hunk")
        map("[h", function() gs.nav_hunk("prev") end, "Prev hunk")
        map("<leader>hs", gs.stage_hunk, "Stage hunk")
        map("<leader>hu", gs.reset_hunk, "Undo (reset) hunk")
        map("<leader>hp", gs.preview_hunk, "Preview hunk")
        map("<leader>hg", gs.toggle_signs, "Toggle git signs")
        map("<leader>hb", function() gs.blame_line({ full = true }) end, "Blame line")
        -- Reading a whole series (see :GitReview): the gutter alone only tells
        -- you a line moved, not what it replaced. These fill that in.
        map("<leader>hd", gs.toggle_deleted, "Show deleted lines inline")
        map("<leader>hw", gs.toggle_word_diff, "Word-level diff")
        map("<leader>hl", gs.toggle_linehl, "Highlight changed lines")
        map("<leader>hi", gs.preview_hunk_inline, "Inline hunk preview")
      end,
    },
  },

  -- Side-by-side diff across many files / branches (your cross-branch migration)
  {
    "sindrets/diffview.nvim",
    cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory" },
    keys = {
      { "<leader>gv", "<cmd>DiffviewOpen<cr>", desc = "Diffview open" },
      { "<leader>gV", "<cmd>DiffviewClose<cr>", desc = "Diffview close" },
      { "<leader>gF", "<cmd>DiffviewFileHistory %<cr>", desc = "File history" },
    },
    opts = {},
  },
}
