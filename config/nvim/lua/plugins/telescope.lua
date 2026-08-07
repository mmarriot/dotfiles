-- ==============================================================================
--  TELESCOPE  (fuzzy finder - replaces the old fzf.vim mappings)
--
--  Keeps your vimrc scheme:
--    ff=files  fg=git files  fr=ripgrep  fb=buffers  fh=history
--    fl=buffer lines  fm=marks  fc=CMSSW src files  fC=CMSSW src grep (.cc/.h/.py)
--  ff and fr respect :Scope when one is set (they narrow to g:scope_dirs).
-- ==============================================================================

return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    "<leader>ff", "<leader>fg", "<leader>fr", "<leader>fb", "<leader>fh",
    "<leader>fl", "<leader>fm", "<leader>fc", "<leader>fC", "<leader>fz", "<leader>fk",
  },
  config = function()
    local telescope = require("telescope")
    local builtin = require("telescope.builtin")

    telescope.setup({
      defaults = {
        layout_strategy = "flex",
        path_display = { "truncate" },
      },
      pickers = {
        find_files = { hidden = false },
      },
    })
    pcall(telescope.load_extension, "fzf")

    -- current :Scope dirs, or nil when no scope is set
    local function scope_dirs()
      local d = vim.g.scope_dirs
      if d == nil or vim.tbl_isempty(d) then
        return nil
      end
      return d
    end

    local function cms_src()
      local base = vim.env.CMSSW_BASE
      return base and (base .. "/src") or nil
    end

    local map = vim.keymap.set

    -- ff / fr are scope-aware
    map("n", "<leader>ff", function()
      builtin.find_files({ search_dirs = scope_dirs() })
    end, { desc = "Find files (scope-aware)" })

    map("n", "<leader>fr", function()
      builtin.live_grep({ search_dirs = scope_dirs() })
    end, { desc = "Ripgrep (scope-aware)" })

    map("n", "<leader>fg", builtin.git_files, { desc = "Git files" })
    map("n", "<leader>fb", builtin.buffers, { desc = "Buffers" })
    map("n", "<leader>fh", builtin.oldfiles, { desc = "Recent files" })
    map("n", "<leader>fl", builtin.current_buffer_fuzzy_find, { desc = "Buffer lines" })
    map("n", "<leader>fm", builtin.marks, { desc = "Marks" })
    map("n", "<leader>fz", builtin.git_status, { desc = "Git status (changed files)" })
    map("n", "<leader>fk", builtin.keymaps, { desc = "Keymaps" })

    -- fc / fC scoped to $CMSSW_BASE/src
    map("n", "<leader>fc", function()
      local src = cms_src()
      builtin.find_files({ search_dirs = src and { src } or nil })
    end, { desc = "Find files under CMSSW src" })

    map("n", "<leader>fC", function()
      local src = cms_src()
      builtin.live_grep({
        search_dirs = src and { src } or nil,
        additional_args = function()
          return { "--glob", "*.cc", "--glob", "*.h", "--glob", "*.py" }
        end,
      })
    end, { desc = "Ripgrep CMSSW src (.cc/.h/.py)" })
  end,
}
