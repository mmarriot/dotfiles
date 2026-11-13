" gruvbox_soft - Gruvbox light, soft background, accents darkened so every
" colour is at least 4.5:1 against the background (plain gruvbox's yellow and
" grey drop to ~3:1). Same colours as the Ghostty theme and the tmux bar.
" Needs termguicolors (set in vimrc); there are no cterm colours. Every group
" still sets cterm= because terminal vim takes bold/reverse/underline from
" cterm= even with termguicolors, and vim's defaults include reverse video.

hi clear
if exists('syntax_on') | syntax reset | endif
set background=light
let g:colors_name = 'gruvbox_soft'

" -- Editor ----------------------------------------------------------------------
hi Normal        guifg=#32302f guibg=#ebe0c0 cterm=NONE gui=NONE
hi CursorLine    guibg=#e0d3ae cterm=NONE gui=NONE
hi CursorColumn  guibg=#e0d3ae cterm=NONE
hi ColorColumn   guibg=#e0d3ae cterm=NONE
hi LineNr        guifg=#6a5f54 guibg=NONE cterm=NONE
hi CursorLineNr  guifg=#05596b guibg=#e0d3ae cterm=bold gui=bold
hi SignColumn    guibg=NONE cterm=NONE
hi FoldColumn    guifg=#6a5f54 guibg=NONE cterm=NONE
hi Folded        guifg=#554d45 guibg=#e0d3ae cterm=italic gui=italic
hi VertSplit     guifg=#bdae93 guibg=NONE cterm=NONE gui=NONE
hi StatusLine    guifg=#32302f guibg=#d5c4a1 cterm=NONE gui=NONE
hi StatusLineNC  guifg=#554d45 guibg=#e0d3ae cterm=NONE gui=NONE
hi StatusLineTerm   guifg=#32302f guibg=#d5c4a1 cterm=NONE gui=NONE
hi StatusLineTermNC guifg=#554d45 guibg=#e0d3ae cterm=NONE gui=NONE
hi TabLine       guifg=#554d45 guibg=#ddcfa6 cterm=NONE gui=NONE
hi TabLineSel    guifg=#32302f guibg=#ebe0c0 cterm=bold gui=bold
hi TabLineFill   guibg=#ddcfa6 cterm=NONE gui=NONE
hi NonText       guifg=#a89984 cterm=NONE
hi EndOfBuffer   guifg=#a89984 cterm=NONE
hi SpecialKey    guifg=#a89984 cterm=NONE
hi Conceal       guifg=#554d45 guibg=NONE cterm=NONE

" Selection matches Ghostty's selection colour; search is soft yellow, the
" current match light orange with dark text, so the current one stands out from the rest.
hi Visual        guifg=NONE    guibg=#d5c4a1 cterm=NONE
hi VisualNOS     guifg=NONE    guibg=#d5c4a1 cterm=NONE
hi Search        guifg=#32302f guibg=#e6c77a cterm=NONE
hi IncSearch     guifg=#7a2500 guibg=#f0c0a0 cterm=bold gui=bold
hi CurSearch     guifg=#7a2500 guibg=#f0c0a0 cterm=bold gui=bold
hi MatchParen    guifg=NONE    guibg=#bdae93 cterm=bold gui=bold
hi QuickFixLine  guibg=#ddcfa6 cterm=bold gui=bold

hi Pmenu         guifg=#32302f guibg=#e0d3ae cterm=NONE
hi PmenuSel      guifg=#32302f guibg=#d5c4a1 cterm=bold gui=bold
hi PmenuSbar     guibg=#ddcfa6 cterm=NONE
hi PmenuThumb    guibg=#a89984 cterm=NONE
hi WildMenu      guifg=#32302f guibg=#d5c4a1 cterm=bold gui=bold

hi Title         guifg=#05596b cterm=bold gui=bold
hi Directory     guifg=#0b5a8f cterm=NONE
hi ModeMsg       guifg=#32302f cterm=bold gui=bold
hi MoreMsg       guifg=#5e5a0a cterm=bold gui=bold
hi Question      guifg=#5e5a0a cterm=bold gui=bold
hi WarningMsg    guifg=#a3330a cterm=bold gui=bold
hi ErrorMsg      guifg=#8f0005 guibg=NONE cterm=bold gui=bold

hi SpellBad      guisp=#8f0005 cterm=undercurl gui=undercurl
hi SpellCap      guisp=#0b5a8f cterm=undercurl gui=undercurl
hi SpellRare     guisp=#7e3563 cterm=undercurl gui=undercurl
hi SpellLocal    guisp=#2f6547 cterm=undercurl gui=undercurl

hi DiffAdd       guifg=NONE    guibg=#d5dba6 cterm=NONE
hi DiffChange    guifg=NONE    guibg=#e8cf9a cterm=NONE
hi DiffText      guifg=NONE    guibg=#e8cf9a cterm=bold,underline gui=bold,underline
hi DiffDelete    guifg=#8f0005 guibg=#ebc3a8 cterm=NONE gui=NONE
hi diffAdded     guifg=#5e5a0a cterm=NONE
hi diffRemoved   guifg=#8f0005 cterm=NONE
hi diffChanged   guifg=#7d5210 cterm=NONE

" -- Syntax ----------------------------------------------------------------------
" Keywords, types and preprocessor are bold. Groups like Conditional, Repeat,
" Include and StorageClass link to these by default and inherit it.
hi Comment       guifg=#6a5f54 cterm=italic gui=italic
hi Constant      guifg=#7e3563 cterm=NONE
hi String        guifg=#5e5a0a cterm=NONE
hi Character     guifg=#5e5a0a cterm=NONE
hi Identifier    guifg=#0b5a8f cterm=NONE gui=NONE
hi Function      guifg=#2f6547 cterm=NONE
hi Statement     guifg=#8f0005 cterm=bold gui=bold
hi Operator      guifg=#32302f cterm=NONE gui=NONE
hi PreProc       guifg=#a3330a cterm=bold gui=bold
hi Type          guifg=#7d5210 cterm=bold gui=bold
hi Special       guifg=#a3330a cterm=NONE
hi Delimiter     guifg=#32302f cterm=NONE
hi Underlined    guifg=#0b5a8f cterm=underline gui=underline
hi Ignore        guifg=#a89984 cterm=NONE
hi Error         guifg=#8f0005 guibg=#f0cbb8 cterm=bold gui=bold
hi Todo          guifg=#7e3563 guibg=NONE cterm=bold,italic gui=bold,italic

" -- Plugins ---------------------------------------------------------------------
hi GitGutterAdd          guifg=#5e5a0a guibg=NONE cterm=NONE
hi GitGutterChange       guifg=#7d5210 guibg=NONE cterm=NONE
hi GitGutterDelete       guifg=#8f0005 guibg=NONE cterm=NONE
hi GitGutterChangeDelete guifg=#8f0005 guibg=NONE cterm=NONE
hi link Floaterm       Normal
hi FloatermBorder guifg=#bdae93 guibg=#ebe0c0 cterm=NONE

" Colours for vim's own terminal (floaterm, :terminal). With termguicolors vim
" draws these itself instead of asking Ghostty, so they repeat Ghostty's palette.
let g:terminal_ansi_colors = [
      \ '#32302f', '#8f0005', '#5e5a0a', '#7d5210', '#0b5a8f', '#7e3563', '#2f6547', '#554d45',
      \ '#6a5f54', '#a3330a', '#4a6b1a', '#875a0c', '#1f5f8a', '#05596b', '#2e6b64', '#1d1c1b']
hi Terminal guifg=#32302f guibg=#ebe0c0 cterm=NONE
