-- ==============================================================================
--  ~/.config/nvim/init.lua
--
--  Neovim config for CMSSW / C++ / Python work on an ssh-only, glibc-2.28 box.
--  Design: standard editor behaviour in clean Lua; the CMSSW-specific machinery
--  (:Scope, the header/path resolver) is reused verbatim from the old ~/.vimrc
--  as sourced vimscript in cmssw.vim - it runs as-is in neovim and there was
--  no reason to rewrite proven code. The terminal toggle (<leader>t) is a
--  floating window, so it lives in Lua (config/terminal.lua) instead.
--
--  LSP note: clangd/clang-format/clang-tidy come from `cmsenv` (CVMFS, built for
--  el8 - so no glibc problems and version-matched to the compiler). Launch nvim
--  from inside a cmsenv and C++ LSP attaches automatically; outside one it just
--  stays quiet. No Mason anywhere.
-- ==============================================================================

-- leader must be set before lazy and before any <leader> mapping is created
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keymaps")
require("config.clipboard")
require("config.worktree")
require("config.terminal")
require("config.lazy")

-- :GitReview - panel of files changed in the last N commits, with gitsigns
-- marking those changes in the live buffers. After lazy, so gitsigns exists.
require("config.gitreview")

-- CMSSW-specific vimscript (paths, :Scope state, run.sh keys). Sourced last
-- so plugins and leader are already in place.
vim.cmd("source " .. vim.fn.stdpath("config") .. "/cmssw.vim")
