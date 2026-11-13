" modus_dusk - Modus Operandi colours, darkened, on a dimmed paper background
" (L* 85 instead of Modus Tinted's 97): less light in a bright room, every
" colour still at least 4.5:1. Same colours as the Ghostty theme and tmux bar.
" Needs termguicolors (set in vimrc); there are no cterm colours. Every group
" still sets cterm= because terminal vim takes bold/reverse/underline from
" cterm= even with termguicolors, and vim's defaults include reverse video.

hi clear
if exists('syntax_on') | syntax reset | endif
set background=light
let g:colors_name = 'modus_dusk'

" -- Editor ----------------------------------------------------------------------
hi Normal        guifg=#141414 guibg=#dad3c6 cterm=NONE gui=NONE
hi CursorLine    guibg=#cfc7b8 cterm=NONE gui=NONE
hi CursorColumn  guibg=#cfc7b8 cterm=NONE
hi ColorColumn   guibg=#cfc7b8 cterm=NONE
hi LineNr        guifg=#5f5a52 guibg=NONE cterm=NONE
hi CursorLineNr  guifg=#43188f guibg=#cfc7b8 cterm=bold gui=bold
hi SignColumn    guibg=NONE cterm=NONE
hi FoldColumn    guifg=#5f5a52 guibg=NONE cterm=NONE
hi Folded        guifg=#45413b guibg=#cfc7b8 cterm=italic gui=italic
hi VertSplit     guifg=#8a8174 guibg=NONE cterm=NONE gui=NONE
hi StatusLine    guifg=#141414 guibg=#bdb3a0 cterm=NONE gui=NONE
hi StatusLineNC  guifg=#45413b guibg=#cfc7b8 cterm=NONE gui=NONE
hi StatusLineTerm   guifg=#141414 guibg=#bdb3a0 cterm=NONE gui=NONE
hi StatusLineTermNC guifg=#45413b guibg=#cfc7b8 cterm=NONE gui=NONE
hi TabLine       guifg=#45413b guibg=#c9c0af cterm=NONE gui=NONE
hi TabLineSel    guifg=#141414 guibg=#dad3c6 cterm=bold gui=bold
hi TabLineFill   guibg=#c9c0af cterm=NONE gui=NONE
hi NonText       guifg=#8a8174 cterm=NONE
hi EndOfBuffer   guifg=#8a8174 cterm=NONE
hi SpecialKey    guifg=#8a8174 cterm=NONE
hi Conceal       guifg=#45413b guibg=NONE cterm=NONE

" Selection matches Ghostty's selection colour; search is muted yellow, the
" current match light violet with dark text, so the current one stands out from the rest.
hi Visual        guifg=NONE    guibg=#b7ac98 cterm=NONE
hi VisualNOS     guifg=NONE    guibg=#b7ac98 cterm=NONE
hi Search        guifg=#141414 guibg=#dcb43e cterm=NONE
hi IncSearch     guifg=#2a0f66 guibg=#bfaee6 cterm=bold gui=bold
hi CurSearch     guifg=#2a0f66 guibg=#bfaee6 cterm=bold gui=bold
hi MatchParen    guifg=#141414 guibg=#7cc4b6 cterm=bold gui=bold
hi QuickFixLine  guibg=#c9c0af cterm=bold gui=bold

hi Pmenu         guifg=#141414 guibg=#cfc7b8 cterm=NONE
hi PmenuSel      guifg=#141414 guibg=#b7ac98 cterm=bold gui=bold
hi PmenuSbar     guibg=#c9c0af cterm=NONE
hi PmenuThumb    guibg=#8a8174 cterm=NONE
hi WildMenu      guifg=#141414 guibg=#b7ac98 cterm=bold gui=bold

hi Title         guifg=#43188f cterm=bold gui=bold
hi Directory     guifg=#00288f cterm=NONE
hi ModeMsg       guifg=#141414 cterm=bold gui=bold
hi MoreMsg       guifg=#0d560d cterm=bold gui=bold
hi Question      guifg=#0d560d cterm=bold gui=bold
hi WarningMsg    guifg=#733d00 cterm=bold gui=bold
hi ErrorMsg      guifg=#8f0000 guibg=NONE cterm=bold gui=bold

hi SpellBad      guisp=#8f0000 cterm=undercurl gui=undercurl
hi SpellCap      guisp=#00288f cterm=undercurl gui=undercurl
hi SpellRare     guisp=#5f0e3a cterm=undercurl gui=undercurl
hi SpellLocal    guisp=#004c50 cterm=undercurl gui=undercurl

hi DiffAdd       guifg=NONE    guibg=#b5d6b0 cterm=NONE
hi DiffChange    guifg=NONE    guibg=#e0c98f cterm=NONE
hi DiffText      guifg=NONE    guibg=#e0c98f cterm=bold,underline gui=bold,underline
hi DiffDelete    guifg=#8f0000 guibg=#e2bcb8 cterm=NONE gui=NONE
hi diffAdded     guifg=#0d560d cterm=NONE
hi diffRemoved   guifg=#8f0000 cterm=NONE
hi diffChanged   guifg=#5f4500 cterm=NONE

" -- Syntax ----------------------------------------------------------------------
" Keywords, types and preprocessor are bold. Groups like Conditional, Repeat,
" Include and StorageClass link to these by default and inherit it.
hi Comment       guifg=#4f4c46 cterm=italic gui=italic
hi Constant      guifg=#1a288c cterm=NONE
hi String        guifg=#29389a cterm=NONE
hi Character     guifg=#29389a cterm=NONE
hi Identifier    guifg=#004f73 cterm=NONE gui=NONE
hi Function      guifg=#5f0e3a cterm=NONE
hi Statement     guifg=#43188f cterm=bold gui=bold
hi Operator      guifg=#141414 cterm=NONE gui=NONE
hi PreProc       guifg=#86142b cterm=bold gui=bold
hi Type          guifg=#004c50 cterm=bold gui=bold
hi Special       guifg=#733d00 cterm=NONE
hi Delimiter     guifg=#141414 cterm=NONE
hi Underlined    guifg=#29389a cterm=underline gui=underline
hi Ignore        guifg=#8a8174 cterm=NONE
hi Error         guifg=#8f0000 guibg=#e6b0a8 cterm=bold gui=bold
hi Todo          guifg=#802000 guibg=NONE cterm=bold,italic gui=bold,italic

" -- Plugins ---------------------------------------------------------------------
hi GitGutterAdd          guifg=#0d560d guibg=NONE cterm=NONE
hi GitGutterChange       guifg=#5f4500 guibg=NONE cterm=NONE
hi GitGutterDelete       guifg=#8f0000 guibg=NONE cterm=NONE
hi GitGutterChangeDelete guifg=#8f0000 guibg=NONE cterm=NONE
" The floating terminal is a lighter panel than the editor, with an accent
" border, so it reads as a separate sheet on top rather than blending in.
hi Floaterm       guifg=#141414 guibg=#e8e2d6 cterm=NONE
hi FloatermBorder guifg=#43188f guibg=#e8e2d6 cterm=NONE
hi link FloatermNC Floaterm

" Colours for vim's own terminal (floaterm, :terminal). With termguicolors vim
" draws these itself instead of asking Ghostty, so they repeat Ghostty's palette.
let g:terminal_ansi_colors = [
      \ '#141414', '#8f0000', '#0d560d', '#5f4500', '#00288f', '#5f0e3a', '#004f73', '#45413b',
      \ '#5f5a52', '#802000', '#2a5500', '#733d00', '#29389a', '#43188f', '#004c50', '#0a0a0a']
hi Terminal guifg=#141414 guibg=#dad3c6 cterm=NONE
