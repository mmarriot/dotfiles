" modus_tinted - Modus Operandi Tinted for vim (light, high contrast).
" Palette from Protesilaos Stavrou's modus-themes. Same colours as the Ghostty
" theme and the tmux bar, so vim, tmux and the shell all match.
" Needs termguicolors (set in vimrc); there are no cterm colours. Every group
" still sets cterm= because terminal vim takes bold/reverse/underline from
" cterm= even with termguicolors, and vim's defaults include reverse video.

hi clear
if exists('syntax_on') | syntax reset | endif
set background=light
let g:colors_name = 'modus_tinted'

" -- Editor ----------------------------------------------------------------------
hi Normal        guifg=#000000 guibg=#fbf7f0 cterm=NONE gui=NONE
hi CursorLine    guibg=#efe9dd cterm=NONE gui=NONE
hi CursorColumn  guibg=#efe9dd cterm=NONE
hi ColorColumn   guibg=#efe9dd cterm=NONE
hi LineNr        guifg=#6f6f6f guibg=NONE cterm=NONE
hi CursorLineNr  guifg=#531ab6 guibg=#efe9dd cterm=bold gui=bold
hi SignColumn    guibg=NONE cterm=NONE
hi FoldColumn    guifg=#6f6f6f guibg=NONE cterm=NONE
hi Folded        guifg=#595959 guibg=#efe9dd cterm=italic gui=italic
hi VertSplit     guifg=#9f9690 guibg=NONE cterm=NONE gui=NONE
hi StatusLine    guifg=#000000 guibg=#c9b9b0 cterm=NONE gui=NONE
hi StatusLineNC  guifg=#595959 guibg=#efe9dd cterm=NONE gui=NONE
hi StatusLineTerm   guifg=#000000 guibg=#c9b9b0 cterm=NONE gui=NONE
hi StatusLineTermNC guifg=#595959 guibg=#efe9dd cterm=NONE gui=NONE
hi TabLine       guifg=#595959 guibg=#dfd5cf cterm=NONE gui=NONE
hi TabLineSel    guifg=#000000 guibg=#fbf7f0 cterm=bold gui=bold
hi TabLineFill   guibg=#dfd5cf cterm=NONE gui=NONE
hi NonText       guifg=#9f9690 cterm=NONE
hi EndOfBuffer   guifg=#9f9690 cterm=NONE
hi SpecialKey    guifg=#9f9690 cterm=NONE
hi Conceal       guifg=#595959 guibg=NONE cterm=NONE

" Selection matches Ghostty's selection colour; search is yellow, the current
" match violet, so the current one stands out from the rest.
hi Visual        guifg=NONE    guibg=#c2bcb5 cterm=NONE
hi VisualNOS     guifg=NONE    guibg=#c2bcb5 cterm=NONE
hi Search        guifg=#000000 guibg=#f5d77a cterm=NONE
hi IncSearch     guifg=#3a0f8a guibg=#d9ccf5 cterm=bold gui=bold
hi CurSearch     guifg=#3a0f8a guibg=#d9ccf5 cterm=bold gui=bold
hi MatchParen    guifg=#000000 guibg=#7fdfcf cterm=bold gui=bold
hi QuickFixLine  guibg=#dfd5cf cterm=bold gui=bold

hi Pmenu         guifg=#000000 guibg=#efe9dd cterm=NONE
hi PmenuSel      guifg=#000000 guibg=#c2bcb5 cterm=bold gui=bold
hi PmenuSbar     guibg=#dfd5cf cterm=NONE
hi PmenuThumb    guibg=#9f9690 cterm=NONE
hi WildMenu      guifg=#000000 guibg=#c2bcb5 cterm=bold gui=bold

hi Title         guifg=#531ab6 cterm=bold gui=bold
hi Directory     guifg=#0031a9 cterm=NONE
hi ModeMsg       guifg=#000000 cterm=bold gui=bold
hi MoreMsg       guifg=#006800 cterm=bold gui=bold
hi Question      guifg=#006800 cterm=bold gui=bold
hi WarningMsg    guifg=#884900 cterm=bold gui=bold
hi ErrorMsg      guifg=#a60000 guibg=NONE cterm=bold gui=bold

hi SpellBad      guisp=#a60000 cterm=undercurl gui=undercurl
hi SpellCap      guisp=#0031a9 cterm=undercurl gui=undercurl
hi SpellRare     guisp=#721045 cterm=undercurl gui=undercurl
hi SpellLocal    guisp=#005f5f cterm=undercurl gui=undercurl

hi DiffAdd       guifg=NONE    guibg=#c3ebc1 cterm=NONE
hi DiffChange    guifg=NONE    guibg=#ffdfa9 cterm=NONE
hi DiffText      guifg=NONE    guibg=#ffdfa9 cterm=bold,underline gui=bold,underline
hi DiffDelete    guifg=#8f1313 guibg=#f4d0cf cterm=NONE gui=NONE
hi diffAdded     guifg=#006800 cterm=NONE
hi diffRemoved   guifg=#a60000 cterm=NONE
hi diffChanged   guifg=#6f5500 cterm=NONE

" -- Syntax ----------------------------------------------------------------------
" Keywords, types and preprocessor are bold, as before. Groups like Conditional,
" Repeat, Include and StorageClass link to these by default and inherit it.
hi Comment       guifg=#595959 cterm=italic gui=italic
hi Constant      guifg=#0000b0 cterm=NONE
hi String        guifg=#3548cf cterm=NONE
hi Character     guifg=#3548cf cterm=NONE
hi Identifier    guifg=#005e8b cterm=NONE gui=NONE
hi Function      guifg=#721045 cterm=NONE
hi Statement     guifg=#531ab6 cterm=bold gui=bold
hi Operator      guifg=#000000 cterm=NONE gui=NONE
hi PreProc       guifg=#a0132f cterm=bold gui=bold
hi Type          guifg=#005f5f cterm=bold gui=bold
hi Special       guifg=#884900 cterm=NONE
hi Delimiter     guifg=#000000 cterm=NONE
hi Underlined    guifg=#3548cf cterm=underline gui=underline
hi Ignore        guifg=#9f9690 cterm=NONE
hi Error         guifg=#a60000 guibg=#f6d6d2 cterm=bold gui=bold
hi Todo          guifg=#972500 guibg=NONE cterm=bold,italic gui=bold,italic

" -- Plugins ---------------------------------------------------------------------
hi GitGutterAdd          guifg=#006800 guibg=NONE cterm=NONE
hi GitGutterChange       guifg=#6f5500 guibg=NONE cterm=NONE
hi GitGutterDelete       guifg=#a60000 guibg=NONE cterm=NONE
hi GitGutterChangeDelete guifg=#a60000 guibg=NONE cterm=NONE
hi link Floaterm       Normal
hi FloatermBorder guifg=#9f9690 guibg=#fbf7f0 cterm=NONE

" Colours for vim's own terminal (floaterm, :terminal). With termguicolors vim
" draws these itself instead of asking Ghostty, so they repeat Ghostty's palette.
let g:terminal_ansi_colors = [
      \ '#000000', '#a60000', '#006800', '#6f5500', '#0031a9', '#721045', '#005e8b', '#595959',
      \ '#6f6f6f', '#972500', '#316500', '#884900', '#3548cf', '#531ab6', '#005f5f', '#1a1a1a']
hi Terminal guifg=#000000 guibg=#fbf7f0 cterm=NONE
