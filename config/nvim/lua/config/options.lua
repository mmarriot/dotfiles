-- ==============================================================================
--  OPTIONS  (ported from the old ~/.vimrc CORE SETTINGS)
-- ==============================================================================

local opt = vim.opt

-- Display
opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.scrolloff = 8
opt.signcolumn = "yes"          -- always show gutter (no jump when signs appear)
opt.wrap = false
opt.colorcolumn = "100"         -- soft column guide at 100 (common in CMSSW)
opt.showmatch = true
opt.termguicolors = true        -- truecolor (gruvbox); tmux passes it through via terminal-features RGB

-- Indentation
opt.shiftwidth = 4
opt.tabstop = 4
opt.softtabstop = 4
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true

-- Search
opt.incsearch = true
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true            -- case-sensitive only if the query has uppercase

-- Buffers & files
opt.hidden = true               -- switch buffers without saving
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.autoread = true             -- reload file if changed outside nvim
opt.undofile = true             -- persistent undo (in ~/.local/state/nvim/undo)

-- Splits open naturally
opt.splitbelow = true
opt.splitright = true

-- Performance / responsiveness
opt.updatetime = 300            -- faster sign + LSP updates

-- Command-line completion
opt.wildmenu = true
opt.wildmode = "list:longest,full"
opt.wildignore:append({ "*.o", "*.so", "*.pyc", "*/.git/*", "*/build/*", "*/tmp/*" })

-- Completion menu behaviour (native <C-x><C-u> CMSSW completion + cmp)
opt.completeopt = "menuone,noselect"

-- Thin beam cursor in every mode - matches the Ghostty/Alacritty cursor style
opt.guicursor = "a:ver25-blinkon0"

-- Re-equalize splits when windows open/close/resize (winfixheight panes exempt)
local eq = vim.api.nvim_create_augroup("auto_equalize_splits", { clear = true })
vim.api.nvim_create_autocmd({ "VimResized", "WinNew" }, {
  group = eq,
  command = "wincmd =",
})

-- Diff mode folds unchanged stretches away as usual (zo/za opens one fold,
-- zR opens every fold in the window) - but a hunk you just made match the
-- other side (diffget, or typing) gets refolded on the very next diff
-- recompute, hiding what you just did. After any edit in a diff window,
-- reveal whatever fold your cursor landed in so your own change stays
-- visible; anything you haven't touched still folds normally.
vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
  group = vim.api.nvim_create_augroup("diff_reveal_own_edits", { clear = true }),
  callback = function()
    if vim.wo.diff then
      pcall(vim.cmd, "normal! zv")
    end
  end,
})
