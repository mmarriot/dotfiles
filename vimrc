" ~/.vimrc - small on purpose. Vim 9.2 (pixi global install vim), leader is space.
"
" Plugins: fzf (find files / grep), fugitive + gitgutter (git), vim-lsp (clangd),
"          oscyank (yanks go to your local clipboard over ssh),
"          floaterm (Ctrl-g toggles a floating terminal; the shell keeps running;
"                    Ctrl-q in it to scroll/search its history, i to type again),
"          dirvish (oil-style file browser, see below).
"
" Going to definitions (works across CMSSW, alpaka and CLUEstering):
"   Ctrl-]    jump to tag under cursor   Ctrl-t  jump back   g]  list all matches
"   :MakeTags index $CMSSW_BASE/src + external headers -> $CMSSW_BASE/tags
"   gd gr K   clangd definition / references / hover. gy  jump to the type of
"             the thing under the cursor. <leader>th  toggle inline types. clangd is from pixi
"             (clang-tools); it needs a compile_commands.json in or above the
"             file: `scram b llvm-ccdb` in CMSSW, CMAKE_EXPORT_COMPILE_COMMANDS
"             in CMake projects (symlink it next to CMakeLists.txt)
"             Python (pyright) and TS/JS (typescript-language-server) get the same keys;
"             a TS project takes a few seconds to load, until then K/gd only see the import
"   Completion pops up as you type: Tab/S-Tab move, Enter accepts, keep typing to ignore
"   gf        open #include under cursor (also alpaka/..., CLUEstering/...)
"
" Files and search (same CMSSW src + externals set; plain cwd outside CMSSW):
"   <leader>ff  files       <leader>fg  grep       <leader>*  grep word under cursor
"   <leader>fb  buffers     <leader>fh  recent files
"
" Git:  <leader>gs status  <leader>gb blame  <leader>gd diff  <leader>gl file log
"       ]c [c next/prev hunk   <leader>hs stage hunk   <leader>hu undo   <leader>hp preview
"       :Review HEAD~2  browse what changed since HEAD~2 (see "Reviewing changes")  :ReviewOff
"       :Changes  explorer tags and gutter signs only, no diffs  :ChangesOff
"
" Files (dirvish): <leader>e or -  open the current file's directory, cursor on it
"   Enter open   -  up a level   o/a  open in split/vsplit   R  reload   gq  close
"   %  new file (name/ for a directory)   r  rename/move   D  delete (also in Visual)
"   A directory is a plain buffer of paths, so / searches it and :Shdo mv/rm/...
"   runs a shell command on the listed (or visually selected) lines.
"
" Ask Claude (vim-ask, ~/src/vim-ask): select code, then
"   <leader>i  explain it (opus, low)   <leader>p  pick a saved prompt (deep: opus, high)
"   <leader>I  type a question, Claude can search the codebase (opus, medium)
"              (-deep in front to use that saved prompt instead: no search)
"   <leader>R  code review of the selection + the file's uncommitted git diff (opus, medium)
"   the language server's types go with the question; the answer pops up beside the code and stays there
"   <leader>o  go into the nearest answer: j/k scroll, f follow up, m minimise, Esc leave, q close
"   answers scroll with the code and go when the file is closed (or :AskClose)
"   :AskModel / :AskEffort  switch model or effort (no argument: menu)   :help ask
"   :AskPrompt [name]  edit a saved prompt for this session; g:ask_prompts to keep it
"
" Machine code (vim-cmssw, ~/src/vim-cmssw): in a CMSSW C++ file
"   <leader>ca  pane with the SASS (kernel lines) or x86 of the file; it follows the cursor
"               both ways. In the pane: t next target, <CR> source line, gd inlined header, q close
"   ]a [a       next/previous block of the current line's instructions
"   <leader>cy  yank the line(s) with their instructions
"   <leader>ce  ask Claude how this C++ becomes these instructions (vim-ask's asm prompt, opus high)
"   <leader>cE  pick which asm* prompt to ask (they're in g:ask_prompts below); <leader>o goes into
"               the answer, from the pane too
"   <leader>cg  rebuild just this file with -g so x86 has line tables (:CmsDebugLog)   :help cmssw
"
" Notes (working beside the code; on screen only, never in the file, gone with the buffer):
"   <leader>n   notes mode: the code is locked and   o  types a note under the line
"               A  a note beside it   (straight in: Enter new line, Backspace, Ctrl-K digraph
"               like a* α, Esc done)   e  edit the line's note in a window with all of vim, q closes
"               dd  deletes the line's notes   <leader>n  leaves
"   <leader>N   hide / show the notes

" cmsenv sets LANG=C, which would make Vim latin1 and lose every non-ASCII character
set encoding=utf-8

let mapleader = ' '

call plug#begin()
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'
Plug 'prabirshrestha/vim-lsp'
Plug 'prabirshrestha/asyncomplete.vim'       " completion pop-up as you type
Plug 'prabirshrestha/asyncomplete-lsp.vim'   " ...fed by clangd (paths: s:PathComplete)
Plug 'ojroques/vim-oscyank', {'branch': 'main'}
Plug 'voldikss/vim-floaterm'
Plug 'justinmk/vim-dirvish'
Plug '~/src/vim-ask'                         " select code, ask Claude about it
Plug '~/src/vim-cmssw'                       " SASS / x86 of the line you're reading
call plug#end()

" -- Settings ------------------------------------------------------------------
set number relativenumber cursorline signcolumn=yes
set expandtab shiftwidth=2 tabstop=2 colorcolumn=120   " CMSSW .clang-format
set softtabstop=-1 shiftround                           " Backspace removes a whole level; >> < snap to levels
set nowrap scrolloff=8 splitbelow splitright hidden
set incsearch hlsearch ignorecase smartcase
set wildmenu wildmode=list:longest,full
set noswapfile nobackup                                 " home is on AFS
set updatetime=300                                      " gitgutter refresh
set backspace=indent,eol,start
set diffopt-=inline:char diffopt+=inline:word            " mark whole changed words, not scattered letters
set ttimeout ttimeoutlen=50                             " no lag after Esc
set laststatus=2
set statusline=\ %f\ %m%r%{get(b:,'notes_mode')?'\ [notes]':''}%{FugitiveHead()!=''?'\ \ ('.FugitiveHead().')':''}%=%y\ %l:%c

" -- Colours ---------------------------------------------------------------------
" True colour: tmux passes it on once tmux.conf has the Tc override. The two
" escape codes tell vim how to send 24-bit colours when TERM is screen-256color.
set termguicolors
let &t_8f = "\<Esc>[38;2;%lu;%lu;%lum"
let &t_8b = "\<Esc>[48;2;%lu;%lu;%lum"
" Modus Dusk: Modus colours on a dimmed paper background, same palette as
" Ghostty and tmux. Schemes live in dotfiles/vim/colors (also: modus_tinted,
" brighter; gruvbox_soft, warmer).
colorscheme modus_dusk

" Cursor: Ghostty draws it (red, from its config); vim only picks the shape.
" Steady block in normal mode, bar in insert, underline in replace, and back to
" Ghostty's default (steady block) on exit.
let &t_te .= "\<Esc>[0 q"
let &t_EI = "\<Esc>[2 q"
let &t_SI = "\<Esc>[6 q"
let &t_SR = "\<Esc>[4 q"

" -- Floating terminal -------------------------------------------------------------
" Ctrl-g opens it, and hides it again from inside (the shell keeps running).
let g:floaterm_keymap_toggle = '<C-g>'
let g:floaterm_width = 0.85
let g:floaterm_height = 0.85
" Scrollback (shell output, Claude chats): Ctrl-q freezes the terminal into a
" read-only vim buffer - Ctrl-u/d, gg/G, / ? n N, v + y (to your clipboard).
" i or a goes back to typing. The mouse wheel can't scroll a vim popup.
tnoremap <C-q> <C-\><C-n>
set termwinscroll=50000                                 " default 10000 lines

" -- Reload files changed on disk ------------------------------------------------
" Git checkouts or edits made from the floating terminal: unmodified buffers
" reload silently, modified ones still prompt. CursorHold covers hiding the
" floaterm popup, which doesn't always fire BufEnter.
set autoread
augroup vimrc_autoread
  autocmd!
  autocmd FocusGained,BufEnter,WinEnter,CursorHold * if mode() !=# 'c' && getcmdwintype() ==# '' | checktime | endif
augroup END

" -- Clipboard -------------------------------------------------------------------
" No X server here, so no +clipboard. Every yank/delete is sent to your local
" clipboard as an OSC52 escape sequence instead; it travels over plain ssh and
" through tmux (set-clipboard on).
let g:oscyank_silent = 1
augroup vimrc_oscyank
  autocmd!
  autocmd TextYankPost * if index(['y', 'd'], v:event.operator) >= 0 && index(['', '+', '*'], v:event.regname) >= 0
        \ | call OSCYankRegister(v:event.regname) | endif
augroup END

" -- Keys ------------------------------------------------------------------------
noremap <leader>w <C-w>k
noremap <leader>a <C-w>h
noremap <leader>s <C-w>j
noremap <leader>d <C-w>l
nnoremap <leader>x :w<CR>
nnoremap <leader>/ :nohlsearch<CR>
nmap - <Plug>(dirvish_up)
nmap <leader>e <Plug>(dirvish_up)
let g:dirvish_mode = ':sort ,^.*[\/],'                 " directories first, like oil
vnoremap > >gv
vnoremap < <gv
xnoremap <Tab> >gv
xnoremap <S-Tab> <gv

" -- Indenting -------------------------------------------------------------------
" Insert-mode Tab / Shift-Tab move through the completion pop-up when it's open.
" Otherwise Shift-Tab takes the line back one level wherever the cursor is, and Tab
" moves to the next indent level (on a markdown list item: nests the whole item).
" In Visual mode they shift the selection, like > and <.
function! s:Tab(dir) abort
  if pumvisible() | return a:dir > 0 ? "\<C-n>" : "\<C-p>" | endif
  let item = &filetype ==# 'markdown' && getline('.') =~# s:md_item
  " <C-g>u first: Vim reads '0 CTRL-D' (just after typing a 0) as 'delete all indent'
  if a:dir < 0 | return "\<C-g>u\<C-d>" . (item ? s:md_renumber : '') | endif
  return item ? "\<C-t>" . s:md_renumber : "\<Tab>"
endfunction
inoremap <expr> <Tab>   <SID>Tab(1)
inoremap <expr> <S-Tab> <SID>Tab(-1)

" C, C++, CUDA: the indent a new line gets follows CMSSW's .clang-format (Google based)
"   g0  public: / private: line up with the class    t0  a return type on its own line
"   i4  ': member_(x)' initializer lists 4 in        +4  continuation lines 4 in
"   (0  arguments line up after an open '('          W4  ...or 4 in when the '(' ends the line
"   l1  'case x: {' bodies line up with the case
" s:CppIndent adds what cinoptions can't: the line after 'template <...>' and
" constructor initializer lists. Against clang-formatted CMSSW files, the indent a
" new line gets is now wrong for ~1% of lines instead of ~9%. gg=G re-indents a whole
" file this way; clang-format is still what gives the exact layout.
function! s:InitListStart(lnum) abort   " the ': member_(...)' line before this '{', or 0
  let l = a:lnum
  while l > 0 && a:lnum - l < 50
    let t = getline(l)
    if t =~# '^\s*:[^:]' | return l | endif
    if l < a:lnum && t =~# '[;{}]\s*$' | return 0 | endif
    let l -= 1
  endwhile
  return 0
endfunction

function! s:CppIndent() abort
  let p = prevnonblank(v:lnum - 1)
  let prev = getline(p)
  let cur = getline(v:lnum)
  " template <...> on its own line: a new declaration follows, not a continuation
  if prev =~# '^\s*template\s*<.*>\s*$'
    return indent(p)
  endif
  " Constructor initializer list:   Foo::Foo(int a)
  "                                     : a_(a),
  "                                       b_(0) {
  "                                   body();
  "                                 }
  if cur =~# '^\s*:[^:]' && prev =~# ')\s*\%(noexcept\)\=\s*$'
    let save = getcurpos()
    call cursor(p, match(prev, ')\s*\%(noexcept\)\=\s*$') + 1)
    let open = searchpair('(', '', ')', 'bnW')
    call setpos('.', save)
    return indent(open > 0 ? open : p) + 4
  endif
  if prev =~# '^\s*:[^:].*,\s*$' && count(prev, '(') == count(prev, ')')
    return indent(p) + 2
  endif
  if prev =~# '{\s*$' && cur !~# '^\s*}'
    let init = s:InitListStart(p)
    if init | return indent(init) - 4 + shiftwidth() | endif
  elseif cur =~# '^\s*}'
    let save = getcurpos()
    call cursor(v:lnum, match(cur, '}') + 1)
    let open = searchpair('{', '', '}', 'bnW')
    call setpos('.', save)
    let init = open > 0 && getline(open) =~# '{\s*$' ? s:InitListStart(open) : 0
    if init | return indent(init) - 4 | endif
  endif
  return cindent(v:lnum)
endfunction

" Python: continuation lines and hanging indents 4 in (PEP 8 / black), not Vim's 8
let g:python_indent = {'open_paren': 'shiftwidth()', 'nested_paren': 'shiftwidth()',
      \ 'continue': 'shiftwidth()', 'closed_paren_align_last_line': v:false}

augroup vimrc_indent
  autocmd!
  autocmd FileType c,cpp,cuda setlocal cinoptions=g0,t0,i4,+4,(0,W4,l1
        \ | let &l:indentkeys = &l:cinkeys | setlocal indentexpr=s:CppIndent()
augroup END

" -- Markdown lists ----------------------------------------------------------------
" Enter on a list item (- * + 1. 1)) starts the next one: numbers count up, to-dos
" come back unticked. Enter on an empty item ends the list (or, nested, moves it out
" a level). o does the same from Normal mode. Tab / Shift-Tab nest an item / move it
" out, wherever the cursor is; a numbered item renumbers to fit its new level.
"   <leader>tt  tick / untick a to-do; turns an item or plain line into one (Visual: each line)
"   ]t [t       next / previous unticked to-do      ]] [[  next / previous heading
let s:md_item = '^\(\s*\)\([-*+]\|\(\d\+\)\([.)]\)\)\(\s\+\)\(\[[ xX]\]\s\+\)\='
let s:md_todo = '^\s*\%([-*+]\|\d\+[.)]\)\s\+\[ \]'
let s:md_renumber = "\<Cmd>call " . expand('<SID>') . "MdRenumber()\<CR>"

" Keys for Enter: a plain one unless the cursor is on a list item's text. The edit
" itself is done by s:MdNewItem, not with keys, so autoindent can't get in the way.
function! s:MdEnter() abort
  let m = matchlist(getline('.'), s:md_item)
  return empty(m) || col('.') <= len(m[0]) && col('.') <= len(getline('.'))
        \ ? "\<CR>" : "\<Cmd>call " . expand('<SID>') . "MdNewItem()\<CR>"
endfunction

function! s:MdNewItem() abort
  let line = getline('.')
  let m = matchlist(line, s:md_item)
  if len(m[0]) == len(line)                     " empty item: end the list, or step out a level
    if empty(m[1]) | call setline('.', '') | else | exe 'normal! <<' | call s:MdRenumber() | endif
    call cursor(line('.'), col('$'))
    return
  endif
  let at = col('.') - 1
  let marker = empty(m[3]) ? m[2] : (m[3] + 1) . m[4]
  let new = m[1] . marker . m[5] . (empty(m[6]) ? '' : '[ ] ')
  call setline('.', line[: at - 1])
  call append('.', new . substitute(line[at :], '^\s\+', '', ''))
  call cursor(line('.') + 1, len(new) + 1)
endfunction

" A numbered item takes the number after the one above it at its level (1 if none)
function! s:MdRenumber() abort
  let m = matchlist(getline('.'), s:md_item)
  if empty(m) || empty(m[3]) | return | endif
  let n = 1
  for l in range(line('.') - 1, 1, -1)
    let t = getline(l)
    if t =~# '^\s*$' || indent(l) > len(m[1]) | continue | endif
    let p = matchlist(t, s:md_item)
    if !empty(p) && indent(l) == len(m[1]) && !empty(p[3]) | let n = p[3] + 1 | endif
    break
  endfor
  if n == m[3] | return | endif
  let col = col('.') + len(n) - len(m[3])
  call setline('.', m[1] . n . getline('.')[len(m[1]) + len(m[3]) :])
  call cursor(line('.'), col)
endfunction

function! s:MdToggle() range abort
  for l in range(a:firstline, a:lastline)
    let t = getline(l)
    let m = matchlist(t, s:md_item)
    if t =~# '^\s*$'
      continue
    elseif empty(m)
      let t = substitute(t, '^\s*\zs', '- [ ] ', '')
    elseif empty(m[6])
      let t = m[0] . '[ ] ' . t[len(m[0]) :]
    else
      let t = m[1] . m[2] . m[5] . (m[6][1] ==# ' ' ? '[x]' : '[ ]') . t[len(m[0]) - len(m[6]) + 3 :]
    endif
    call setline(l, t)
  endfor
endfunction

function! s:MdItem() abort
  return getline('.') =~# s:md_item
endfunction

function! s:MdTodo(flags) abort
  if a:flags =~# 'b' | call cursor(line('.'), 1) | endif   " not the to-do the cursor is on
  call search(s:md_todo, a:flags)
endfunction

augroup vimrc_markdown
  autocmd!
  autocmd FileType markdown nmap <buffer><expr> o <SID>MdItem() ? "A\<CR>" : 'o'
  autocmd FileType markdown nnoremap <buffer><silent> <leader>tt :call <SID>MdToggle()<CR>
  autocmd FileType markdown xnoremap <buffer><silent> <leader>tt :call <SID>MdToggle()<CR>
  autocmd FileType markdown nnoremap <buffer><silent> ]t :<C-u>call <SID>MdTodo('sW')<CR>
  autocmd FileType markdown nnoremap <buffer><silent> [t :<C-u>call <SID>MdTodo('bsW')<CR>
augroup END

nnoremap <leader>ff :CmsFiles<CR>
nnoremap <leader>fg :CmsGrep<Space>
nnoremap <leader>*  :CmsGrep <C-r><C-w><CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fh :History<CR>
let g:fzf_layout = { 'down': '40%' }

nnoremap <leader>gs :Git<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>
nnoremap <leader>gl :0Gclog<CR>

" -- File operations in dirvish ----------------------------------------------------
" %  new file, or a directory if the name ends in /    (a/b/c.txt makes a/ and b/ too)
" r  rename or move (to an existing directory: moves into it)
" D  delete, asks first; {Visual}D deletes every selected line; directories recursively
function! s:DirvishNew() abort
  let dir = expand('%:p')
  let name = input('New (end with / for a directory): ', dir, 'file')
  if empty(name) || name ==# dir | return | endif
  if filereadable(name) || isdirectory(name) | echo "\nAlready exists: " . name | return | endif
  call mkdir(name =~# '/$' ? name : fnamemodify(name, ':h'), 'p')
  if name !~# '/$' | call writefile([], name) | endif
  Dirvish %
  call search('\V\^' . escape(fnamemodify(name, ':p'), '\') . '\$')
endfunction

function! s:DirvishRename() abort
  let old = substitute(getline('.'), '/$', '', '')
  let new = input('Rename to: ', old, 'file')
  if empty(new) || new ==# old | return | endif
  if isdirectory(new) | let new = substitute(new, '/$', '', '') . '/' . fnamemodify(old, ':t') | endif
  if filereadable(new) || isdirectory(new) | echo "\nAlready exists: " . new | return | endif
  call mkdir(fnamemodify(new, ':h'), 'p')
  if rename(old, new) | echo "\nRename failed: " . old | return | endif
  Dirvish %
  call search('\V\^' . escape(fnamemodify(new, ':p'), '\') . '\$')
endfunction

function! s:DirvishDelete() range abort
  let paths = getline(a:firstline, a:lastline)
  let what = len(paths) == 1 ? fnamemodify(paths[0], ':~:.') : len(paths) . ' items'
  if confirm('Delete ' . what . '?', "&Yes\n&No", 2) != 1 | return | endif
  for p in paths
    if delete(substitute(p, '/$', '', ''), p =~# '/$' ? 'rf' : '')
      echohl ErrorMsg | echomsg 'Could not delete ' . p | echohl None
    endif
  endfor
  Dirvish %
endfunction

augroup vimrc_dirvish
  autocmd!
  autocmd FileType dirvish nnoremap <buffer><silent> % :call <SID>DirvishNew()<CR>
  autocmd FileType dirvish nnoremap <buffer><silent> r :call <SID>DirvishRename()<CR>
  autocmd FileType dirvish nnoremap <buffer><silent> D :call <SID>DirvishDelete()<CR>
  autocmd FileType dirvish xnoremap <buffer><silent> D :call <SID>DirvishDelete()<CR>
augroup END

" -- Reviewing changes: :Review <rev> ------------------------------------------------
" Compares the working tree with <rev> (default HEAD, i.e. uncommitted changes;
" :Review HEAD~2 for the last two commits) until :ReviewOff. Meanwhile:
"   explorer (<leader>e)    changed files are tagged M/A/R (untracked ones as A), directories say how many
"                           changed files they hold, deleted files are listed below
"   opening a changed file  <rev> on the left, your file on the right; ]c [c jump
"                           between changes, <leader>e goes back and closes the left side
"   gitgutter signs and the quickfix list (:copen, every changed file) use <rev> too
" :Changes <rev> is the same without the diff: files open normally, with their gutter
" signs. The tags are a snapshot: run :Changes again to update them. :ChangesOff ends it.
let s:review = {}   " {'rev': ..., 'diff': 0/1, 'files': {abs path: {'status': M/A/R/D, 'old': path at rev}}}

function! s:Review(rev, diff) abort
  let root = FugitiveWorkTree()
  if empty(root) | echo 'Not in a git repository' | return | endif
  let lines = systemlist('git -C ' . shellescape(root) . ' diff --name-status -M ' . shellescape(a:rev))
  if v:shell_error | echoerr join(lines) | return | endif
  " git diff never lists untracked files: count them as added
  let untracked = systemlist('git -C ' . shellescape(root) . ' ls-files --others --exclude-standard')
  if v:shell_error | echoerr join(untracked) | return | endif
  call extend(lines, map(untracked, '"A\t" . v:val'))
  let s:review = {'rev': a:rev, 'diff': a:diff, 'files': {}}
  let qf = []
  for line in lines
    let f = split(line, "\t")     " M path | A path | D path | R095 old new
    let file = {'status': f[0][0], 'old': f[1]}
    let s:review.files[root . '/' . f[-1]] = file
    call add(qf, {'filename': file.status ==# 'D' ? FugitiveFind(a:rev . ':' . f[1]) : root . '/' . f[-1],
          \ 'text': file.status ==# 'R' ? 'R  from ' . f[1] : file.status})
  endfor
  call setqflist([], ' ', {'title': 'Review ' . a:rev, 'items': qf})
  let g:gitgutter_diff_base = a:rev
  GitGutterAll
  if !a:diff | call s:ReviewCloseDiff() | endif
  call s:ReviewRefresh()
  echo len(qf) . ' files changed since ' . a:rev . '  (<leader>e to browse them, :copen to list them)'
endfunction

function! s:ReviewOff() abort
  let s:review = {}
  let g:gitgutter_diff_base = ''
  GitGutterAll
  call s:ReviewCloseDiff()
  call s:ReviewRefresh()
endfunction

function! s:ReviewRefresh() abort
  if &filetype ==# 'dirvish' | call s:ReviewExplorer() | else | call s:ReviewDiff(bufnr()) | endif
endfunction

" Close the <rev> side of this tab's review diff
function! s:ReviewCloseDiff() abort
  let closed = 0
  for w in reverse(range(1, winnr('$')))
    if !empty(getwinvar(w, 'review_base')) | execute w . 'close' | let closed = 1 | endif
  endfor
  if closed
    diffoff!
    for w in range(1, winnr('$')) | call setwinvar(w, '&cursorlineopt', 'both') | endfor
  endif
endfunction

" Put <rev> of the file shown in this window on its left (timer after BufWinEnter)
function! s:ReviewDiff(bufnr, ...) abort
  if empty(s:review) || !s:review.diff || bufnr() != a:bufnr || &buftype !=# '' | return | endif
  let path = expand('%:p')
  if !empty(filter(range(1, winnr('$')), 'getwinvar(v:val, "review_base") ==# path')) | return | endif
  call s:ReviewCloseDiff()
  let file = get(s:review.files, path, {})
  if empty(file) || file.status ==# 'A' | return | endif
  let win = win_getid()
  execute 'leftabove Gvdiffsplit' fnameescape(s:review.rev . ':' . file.old)
  for w in range(1, winnr('$'))
    if !getwinvar(w, '&diff') | continue | endif
    " cursorline would repaint the (cursor-bound) current line in both panes; keep it to the number
    call setwinvar(w, '&cursorlineopt', 'number')
    if win_getid(w) != win
      call setwinvar(w, 'review_base', path)
      " gitgutter would compare <rev> with its own parent there: signs unrelated to this review
      call win_execute(win_getid(w), 'GitGutterBufferDisable')
    endif
  endfor
  call win_gotoid(win)
endfunction

" Tag changed files and directories in a dirvish listing, list deleted ones below it
function! s:ReviewExplorer(...) abort
  if &filetype !=# 'dirvish' | return | endif
  call s:ReviewCloseDiff()
  let types = ['M', 'R', 'A', 'D', 'dir']
  for [t, hl] in [['M', 'GitGutterChange'], ['R', 'GitGutterChange'], ['A', 'GitGutterAdd'],
        \ ['D', 'GitGutterDelete'], ['dir', 'Comment']]
    if empty(prop_type_get('review_' . t)) | call prop_type_add('review_' . t, {'highlight': hl}) | endif
  endfor
  call prop_remove({'types': map(copy(types), '"review_" . v:val'), 'all': 1})
  if empty(s:review) | return | endif
  let paths = keys(s:review.files)
  for lnum in range(1, line('$'))
    let line = getline(lnum)
    if line =~# '/$'
      let n = len(filter(copy(paths), 'stridx(v:val, line) == 0'))
      if n | call prop_add(lnum, 0, {'type': 'review_dir', 'text': n . ' changed', 'text_align': 'after', 'text_padding_left': 2}) | endif
    elseif has_key(s:review.files, line)
      let file = s:review.files[line]
      call prop_add(lnum, 0, {'type': 'review_' . file.status, 'text_align': 'after', 'text_padding_left': 2,
            \ 'text': file.status ==# 'R' ? 'R  from ' . file.old : file.status})
    endif
  endfor
  " Deleted files (or whole deleted directories) that used to be in this directory
  let dir = b:dirvish._dir
  let gone = {}
  for [path, file] in items(s:review.files)
    if file.status ==# 'D' && stridx(path, dir) == 0
      let gone[matchstr(path[len(dir):], '^[^/]*/\=')] = 1
    endif
  endfor
  for name in sort(filter(keys(gone), '!filereadable(dir . v:val) && !isdirectory(dir . v:val)'))
    call prop_add(line('$'), 0, {'type': 'review_D', 'text': 'D  ' . name, 'text_align': 'below'})
  endfor
endfunction

command! -nargs=? Review call s:Review(empty(<q-args>) ? 'HEAD' : <q-args>, 1)
command! ReviewOff call s:ReviewOff()
command! -nargs=? Changes call s:Review(empty(<q-args>) ? 'HEAD' : <q-args>, 0)
command! ChangesOff call s:ReviewOff()

augroup vimrc_review
  autocmd!
  " Timers: dirvish forbids its FileType handlers to change windows, and splitting
  " in the middle of opening a buffer confuses the other BufWinEnter handlers
  autocmd FileType dirvish call timer_start(0, function('s:ReviewExplorer'))
  autocmd BufWinEnter * if !empty(s:review)
        \ | call timer_start(0, function('s:ReviewDiff', [str2nr(expand('<abuf>'))])) | endif
augroup END

" -- CMSSW + externals -----------------------------------------------------------
" The dirs everything searches: the area's src/ plus the include dirs of these
" scram externals. Read from the area's tool files (first line has path="...")
" rather than `scram tool tag`, which prints nothing under an el9 cmsenv here.
let g:cms_externals = ['alpaka', 'cluestering']

function! s:CmsDirs() abort
  if exists('s:cms_dirs') | return s:cms_dirs | endif
  let s:cms_dirs = []
  let scram = finddir('.SCRAM', getcwd() . ';')
  let base = !empty($CMSSW_BASE) ? $CMSSW_BASE : empty(scram) ? '' : fnamemodify(scram, ':p:h:h')
  if empty(base) | return s:cms_dirs | endif
  call add(s:cms_dirs, base . '/src')
  for tool in g:cms_externals
    let xml = glob(base . '/config/toolbox/*/tools/selected/' . tool . '.xml', 1, 1)
    let inc = empty(xml) ? '' : matchstr(readfile(xml[0], '', 1)[0], 'path="\zs[^"]*') . '/include'
    if isdirectory(inc) | call add(s:cms_dirs, inc) | endif
  endfor
  " gf: #include paths are relative to src/ or to an external's include/.
  " The release areas (set by cmsenv) cover packages you haven't checked out.
  let releases = map(filter([$CMSSW_RELEASE_BASE, $CMSSW_FULL_RELEASE_BASE], '!empty(v:val)'), "v:val . '/src'")
  let &path .= ',' . join(s:cms_dirs + releases, ',')
  let &tags .= ',' . base . '/tags'
  return s:cms_dirs
endfunction

" Search dirs as shell args, cwd-relative where possible so fzf lines stay short
function! s:CmsArgs() abort
  return join(map(copy(s:CmsDirs()), "shellescape(v:val ==# getcwd() ? '.' : fnamemodify(v:val, ':~:.'))"))
endfunction

function! s:MakeTags() abort
  let dirs = s:CmsDirs()
  if empty(dirs) | echo 'Not in a CMSSW area' | return | endif
  let out = fnamemodify(dirs[0], ':h') . '/tags'
  echo 'Indexing in the background: ' . join(dirs)
  call job_start(['ctags', '-R', '-f', out, '--languages=C,C++,Python', '--langmap=c++:+.cu.cuh',
        \ '--c++-kinds=+p', '--exclude=.git'] + dirs,
        \ {'exit_cb': {job, status -> execute('echomsg "MakeTags ' . (status ? 'failed' : 'done') . ': ' . out . '"', '')}})
endfunction

command! MakeTags call s:MakeTags()
command! CmsFiles call fzf#run(fzf#wrap({'source': 'rg --files ' . s:CmsArgs()}))
command! -nargs=* CmsGrep call fzf#vim#grep('rg --column --line-number --no-heading --color=always --smart-case -- '
      \ . shellescape(<q-args>) . ' ' . s:CmsArgs())

augroup vimrc_cmssw
  autocmd!
  " Reopen files where you left off
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe 'normal! g`"' | endif
  autocmd FileType c,cpp,cuda,python call s:CmsDirs()
augroup END

" -- clangd: only if it actually runs here ----------------------------------------
let g:lsp_diagnostics_enabled = 0
let g:lsp_document_highlight_enabled = 0
set completeopt=menuone,noinsert,noselect
" Enter accepts the selected pop-up item (Tab/S-Tab move in it, see "Indenting").
" Otherwise it's a new line, even with the pop-up open (a bare Enter would only close
" it); in markdown that continues the list.
function! s:Enter() abort
  if pumvisible() && complete_info().selected != -1 | return asyncomplete#close_popup() | endif
  return (pumvisible() ? "\<C-e>" : '') . (&filetype ==# 'markdown' ? s:MdEnter() : "\<CR>")
endfunction
inoremap <expr> <CR> <SID>Enter()

" Inlay hints: grey virtual text with the deduced type after every `auto` and the
" parameter name before every call argument. <leader>th toggles them.
let g:lsp_inlay_hints_enabled = 1
function! s:ToggleInlayHints() abort
  let g:lsp_inlay_hints_enabled = !g:lsp_inlay_hints_enabled
  if !g:lsp_inlay_hints_enabled
    call prop_remove({'type': 'vim_lsp_inlay_hint_type', 'all': 1})
    call prop_remove({'type': 'vim_lsp_inlay_hint_parameter', 'all': 1})
  endif
endfunction

function! s:LspBuffer() abort
  nmap <buffer> gd <Plug>(lsp-definition)
  nmap <buffer> gr <Plug>(lsp-references)
  nmap <buffer> gy <Plug>(lsp-type-definition)
  nmap <buffer> K  <Plug>(lsp-hover)
  nnoremap <buffer><silent> <leader>th :call <SID>ToggleInlayHints()<CR>
endfunction

" One compile DB per CMSSW area, so headers from the release on /cvmfs and from
" alpaka are parsed with this area's flags too (otherwise clangd finds the
" release's own compile_commands.json and tries to index all of CMSSW into
" read-only /cvmfs). -j: clangd's default is one worker per core, 256 here, at
" up to ~1 GB per CMSSW file being indexed.
function! s:ClangdCmd() abort
  let cmd = ['clangd', '--background-index', '--background-index-priority=low', '-j=8',
        \ '--query-driver=/cvmfs/**,/opt/rh/**']
  let dirs = s:CmsDirs()
  let scram = finddir('.SCRAM', expand('%:p:h') . ';')
  let base = !empty(dirs) ? fnamemodify(dirs[0], ':h') : empty(scram) ? '' : fnamemodify(scram, ':p:h:h')
  if filereadable(base . '/compile_commands.json')
    call add(cmd, '--compile-commands-dir=' . base)
  endif
  return cmd
endfunction

if executable('clangd')
  call system('clangd --version')
  if !v:shell_error
    augroup vimrc_lsp
      autocmd!
      autocmd User lsp_setup call lsp#register_server({'name': 'clangd',
            \ 'cmd': {_ -> s:ClangdCmd()},
            \ 'initialization_options': {'fallbackFlags': ['-std=c++20',
            \   '--gcc-install-dir=/opt/rh/gcc-toolset-13/root/usr/lib/gcc/x86_64-redhat-linux/13']},
            \ 'allowlist': ['c', 'cpp', 'cuda']})
      " CMSSW's libstdc++: the compile DB passes --gcc-toolchain=<cvmfs gcc>, but pixi's
      " clangd targets x86_64-conda-linux-gnu and only finds gcc under a matching
      " triple; cvmfs gcc is x86_64-redhat-linux-gnu. ~/.config/clangd/config.yaml
      " adds that --target for CMSSW files (without it: 'cstdint' file not found).
      " fallbackFlags: only used when there's no compile_commands.json -> C++20 with
      " gcc-toolset-13's headers instead of the system gcc 8 ones
    augroup END
  endif
endif

" CMake (CMakeLists.txt, *.cmake), Python and TS/JS get the same pop-up and gd/gr/K
augroup vimrc_lsp_more
  autocmd!
  if executable('neocmakelsp')          " pixi global install neocmakelsp
    autocmd User lsp_setup call lsp#register_server({'name': 'neocmakelsp',
          \ 'cmd': {_ -> ['neocmakelsp', 'stdio']},
          \ 'allowlist': ['cmake']})
  endif
  if executable('pyright-langserver')   " npm i -g pyright
    autocmd User lsp_setup call lsp#register_server({'name': 'pyright',
          \ 'cmd': {_ -> ['pyright-langserver', '--stdio']},
          \ 'workspace_config': {'python': {'analysis': {'autoSearchPaths': v:true}}},
          \ 'allowlist': ['python']})
  endif
  " npm i -g typescript-language-server@5.3.0 typescript@6.0.3 (6.x of the server needs node >= 22.22;
  " typescript 7 has no tsserver). Root: nearest tsconfig/package.json, so the server uses that
  " project's node_modules/typescript; the global one only for loose files.
  if executable('typescript-language-server')
    autocmd User lsp_setup call lsp#register_server({'name': 'typescript-language-server',
          \ 'cmd': {_ -> ['typescript-language-server', '--stdio']},
          \ 'root_uri': {_ -> lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(
          \   lsp#utils#get_buffer_path(), ['tsconfig.json', 'jsconfig.json', 'package.json', '.git/']))},
          \ 'allowlist': ['typescript', 'typescriptreact', 'javascript', 'javascriptreact']})
  endif
  if executable('metals')               " Scala: source /data/mmarriot/scala/env.sh first
    " Root: nearest dir with a build file, so vim can be started from anywhere above it.
    " Metals builds through .bsp/ (see env.sh); the first open indexes for a minute.
    " Doctor as json: otherwise Metals asks to start its HTTP server on every connect
    autocmd User lsp_setup call lsp#register_server({'name': 'metals',
          \ 'cmd': {_ -> ['metals']},
          \ 'root_uri': {_ -> lsp#utils#path_to_uri(lsp#utils#find_nearest_parent_file_directory(
          \   lsp#utils#get_buffer_path(), ['build.scala', 'project.scala', 'build.sbt', '.git/']))},
          \ 'initialization_options': {'doctorProvider': 'json', 'executeClientCommandProvider': v:true},
          \ 'allowlist': ['scala', 'sbt']})
  endif
  autocmd User lsp_buffer_enabled call s:LspBuffer()
augroup END

" -- Notes: virtual text beside the code ---------------------------------------------
" A note is drawn with text properties that carry a 'text' (virtual text): vim shows
" it in the window but it isn't in the buffer, so :w, yanks, git and clangd never see
" it and it doesn't mark the buffer modified. Each note hangs off a zero-width
" 'note_anchor' property on its line, so it moves with the code; dd on that line takes
" the note away and u brings it back. b:notes holds the text, by anchor id:
" {'where': 'below' or 'after', 'lines': [...]}. Nothing is saved anywhere.
let s:note_id = get(s:, 'note_id', 0)   " kept on :source, so new ids never reuse a live note's

" Colour schemes start with :hi clear, which drops NoteText, so set it again after each
function! s:NoteColours() abort
  hi NoteText guifg=#004c50 guibg=#c3d3cc ctermfg=23 ctermbg=152 cterm=NONE gui=NONE
endfunction
call s:NoteColours()
augroup vimrc_notes
  autocmd!
  autocmd ColorScheme * call s:NoteColours()
augroup END
" after NoteText exists: a type made with an unknown highlight group gets no colour
if empty(prop_type_get('note_anchor'))
  call prop_type_add('note_anchor', {})
  call prop_type_add('note_below', {'highlight': 'NoteText'})
  call prop_type_add('note_after', {'highlight': 'NoteText'})
endif

" Redraw all of buffer buf's notes from b:notes (none while they're hidden)
function! s:NotesDraw(buf) abort
  call prop_remove({'type': 'note_below', 'bufnr': a:buf, 'all': 1})
  call prop_remove({'type': 'note_after', 'bufnr': a:buf, 'all': 1})
  if getbufvar(a:buf, 'notes_hidden') | return | endif
  let notes = getbufvar(a:buf, 'notes', {})
  for a in prop_list(1, {'bufnr': a:buf, 'end_lnum': -1, 'types': ['note_anchor']})
    let note = notes[a.id]
    " the note being typed into gets a cursor at its end
    let lines = get(note, 'typing') ? note.lines[:-2] + [note.lines[-1] . '▏'] : note.lines
    if note.where ==# 'after'
      call prop_add(a.lnum, 0, {'bufnr': a:buf, 'type': 'note_after', 'text': join(lines, '  '),
            \ 'text_align': 'after', 'text_padding_left': 2})
      continue
    endif
    " under the line, lined up with its indent
    let pad = strdisplaywidth(matchstr(getbufline(a:buf, a.lnum)[0], '^\s*'))
    for line in lines
      call prop_add(a.lnum, 0, {'bufnr': a:buf, 'type': 'note_below', 'text': line,
            \ 'text_align': 'below', 'text_padding_left': pad, 'text_wrap': 'wrap'})
    endfor
  endfor
endfunction

" The anchor id of this line's note that goes `where`, 0 if it has none
function! s:NoteAt(lnum, where) abort
  for a in prop_list(a:lnum, {'types': ['note_anchor']})
    if b:notes[a.id].where ==# a:where | return a.id | endif
  endfor
  return 0
endfunction

" This line's note that goes `where`, made (empty) if it has none
function! s:NoteGet(where) abort
  let id = s:NoteAt(line('.'), a:where)
  if !id
    let s:note_id += 1
    let id = s:note_id
    call prop_add(line('.'), 1, {'type': 'note_anchor', 'id': id, 'length': 0})
    let b:notes[id] = {'where': a:where, 'lines': ['']}
  endif
  return id
endfunction

" Done with note id of buffer buf: drop its trailing blank lines, and the note if that empties it
function! s:NoteDone(buf, id) abort
  let notes = getbufvar(a:buf, 'notes')
  let lines = notes[a:id].lines
  while !empty(lines) && lines[-1] =~ '^\s*$' | call remove(lines, -1) | endwhile
  if empty(lines)
    call remove(notes, a:id)
    call prop_remove({'type': 'note_anchor', 'id': a:id, 'both': 1, 'bufnr': a:buf})
  endif
  call s:NotesDraw(a:buf)
endfunction

" Type straight into this line's note that goes `where`: o adds a line to the note under
" the code, A carries on the one beside it. Each key goes into the note's text, never the
" buffer: Enter starts a new line (ends a note beside the code), Backspace deletes, Ctrl-U
" clears the line, Ctrl-K + two keys is a digraph (a* α, S* Σ, -> →, =< ≤; :digraphs), Esc ends.
function! s:NoteType(where) abort
  let buf = bufnr()
  let id = s:NoteGet(a:where)
  let note = b:notes[id]
  if a:where ==# 'below' && note.lines != [''] | call add(note.lines, '') | endif
  let note.typing = 1
  try
    while 1
      call s:NotesDraw(buf)
      redraw
      echo '-- NOTE --  Enter new line, Backspace delete, Esc done'
      let c = getcharstr()
      let lines = note.lines
      if c ==# "\<Esc>" || (c ==# "\<CR>" && a:where ==# 'after')
        break
      elseif c ==# "\<CR>"
        call add(lines, '')
      elseif c ==# "\<BS>" || c ==# "\<C-h>"
        if lines[-1] ==# '' && len(lines) > 1
          call remove(lines, -1)
        else
          let lines[-1] = strcharpart(lines[-1], 0, strchars(lines[-1]) - 1)
        endif
      elseif c ==# "\<C-u>"
        let lines[-1] = ''
      elseif c ==# "\<C-k>"
        silent! let lines[-1] .= digraph_get(getcharstr() . getcharstr())
      elseif c =~# '^\p\+$'     " printable, which leaves out arrows and other special keys
        let lines[-1] .= c
      endif
    endwhile
  finally                         " also on Ctrl-C
    unlet note.typing
    call s:NoteDone(buf, id)
    redraw                        " property changes alone don't repaint, so the cursor would linger
    echo ''
  endtry
endfunction

" Edit this line's note (the one under it if there are both) in a small window below,
" with all of vim's editing. It's drawn as you type; q closes the window.
function! s:NoteEdit() abort
  let where = s:NoteAt(line('.'), 'after') && !s:NoteAt(line('.'), 'below') ? 'after' : 'below'
  let id = s:NoteGet(where)
  let buf = bufnr()
  let lines = b:notes[id].lines
  execute 'belowright' max([4, len(lines) + 2]) 'new'
  setlocal buftype=nofile bufhidden=wipe noswapfile
  execute 'silent! file note-' . id
  call setline(1, lines)
  let b:note = [buf, id]
  nnoremap <buffer> q <Cmd>close<CR>
  autocmd TextChanged,TextChangedI <buffer> call s:NoteSave(bufnr(), 0)
  autocmd BufWinLeave <buffer> call s:NoteSave(str2nr(expand('<abuf>')), 1)
endfunction

" Copy the editing window's text (buffer nb) into its note and redraw
function! s:NoteSave(nb, closing) abort
  let [buf, id] = getbufvar(a:nb, 'note')
  let notes = getbufvar(buf, 'notes')
  if !has_key(notes, id) | return | endif     " deleted with dd meanwhile
  let notes[id].lines = getbufline(a:nb, 1, '$')
  if a:closing | call s:NoteDone(buf, id) | else | call s:NotesDraw(buf) | endif
endfunction

function! s:NotesDelete() abort
  for a in prop_list(line('.'), {'types': ['note_anchor']})
    call remove(b:notes, a.id)
  endfor
  call prop_remove({'type': 'note_anchor', 'all': 1}, line('.'))
  call s:NotesDraw(bufnr())
endfunction

" Notes mode: lock the code and give o / A / e / dd to the notes, or hand them back
function! s:NotesMode() abort
  if get(b:, 'notes_mode')
    let b:notes_mode = 0
    let &l:modifiable = b:notes_modifiable
    silent! nunmap <buffer> o
    silent! nunmap <buffer> A
    silent! nunmap <buffer> e
    silent! nunmap <buffer> dd
    echo 'Notes mode off'
    return
  endif
  let b:notes_mode = 1
  let b:notes_modifiable = &l:modifiable
  let b:notes = get(b:, 'notes', {})
  let b:notes_hidden = 0
  setlocal nomodifiable
  call s:NotesDraw(bufnr())
  nnoremap <buffer> o <Cmd>call <SID>NoteType('below')<CR>
  nnoremap <buffer> A <Cmd>call <SID>NoteType('after')<CR>
  nnoremap <buffer> e <Cmd>call <SID>NoteEdit()<CR>
  nnoremap <buffer> dd <Cmd>call <SID>NotesDelete()<CR>
  echo 'Notes mode: o note under the line, A beside it, e edit in a window, dd delete, <leader>n leave'
endfunction

function! s:NotesHide() abort
  let b:notes_hidden = !get(b:, 'notes_hidden')
  call s:NotesDraw(bufnr())
endfunction

nnoremap <leader>n <Cmd>call <SID>NotesMode()<CR>
nnoremap <leader>N <Cmd>call <SID>NotesHide()<CR>

" -- Ask Claude (vim-ask) ----------------------------------------------------------
" Saved prompts: <leader>p picks one, :Ask -name runs one, <leader>I with "-name ..." uses
" one's model and effort for a typed question. A prompt without 'model' or 'effort' uses
" g:ask_model / g:ask_effort (which :AskModel / :AskEffort change). These are the
" plugin's defaults written out; add your own alongside. :help ask-prompts
let g:ask_prompts = {
      \ 'explain': {'prompt': 'Briefly explain what this code does: the types involved, what each part '
      \                     . 'returns, and any syntax that is not obvious.'},
      \ 'deep':    {'prompt': 'Explain this code in depth: what it does and why, the types and what each '
      \                     . 'call returns, the language features it relies on, and anything subtle or '
      \                     . 'easy to get wrong. Take as many lines as it needs.',
      \             'effort': 'high'},
      "\ Machine code (vim-cmssw): every prompt named asm* gets the pane's instructions for the
      "\ selection, their lines, inline chains and inlined source. <leader>ce asks 'asm',
      "\ <leader>cE picks one of these. 'system_prompt' replaces vim-ask's (which keeps answers
      "\ to ~15 lines); without one, vim-ask's is used.
      \ 'asm':       {'model': 'claude-opus-5-5', 'effort': 'high',
      \               'system_prompt': 'You explain how C++ compiles to machine code, to a physicist who '
      \                 . 'develops and reviews CMSSW (CMS) reconstruction code and is learning how source maps '
      \                 . 'onto the hardware. You are given the C++, the instructions the compiler produced for it '
      \                 . 'with the source line and inline chain of each, and the source text of every inlined '
      \                 . 'frame. Base every claim on that listing and cite instructions by address (`01a0`); '
      \                 . 'where it does not show something, say so instead of guessing. The answer is read in a '
      \                 . 'popup in Vim: no preamble, short paragraphs or bullets, light Markdown, as long as needed.',
      \               'prompt': 'Explain how this C++ becomes the machine code listed. Walk through the instructions '
      \                 . 'in order, grouping them by the C++ expression and inlined frame they implement. For each '
      \                 . 'group say what the hardware does (loads and stores and their kind, address arithmetic, '
      \                 . 'predicates and branches, vector width, registers) and what it scales with (per element, '
      \                 . 'per thread, per call). Point out anything surprising or costly (bounds checks, error or '
      \                 . 'trap paths, spills, redundant work, missed vectorisation, calls that were not inlined) '
      \                 . 'and what in the source causes it. Keep the mechanism, which the listing shows, apart from '
      \                 . 'the magnitude, which only a measurement can show, and say how to measure it.'},
      \ 'asm-brief': {'model': 'claude-opus-5-5', 'effort': 'medium',
      \               'prompt': 'From the machine code listed: what does this C++ compile to, in a few bullets citing '
      \                 . 'instruction addresses, and the one or two things about it that matter for performance. '
      \                 . 'Only claim what the listing shows.'},
      "\ <leader>R: the file's uncommitted diff goes with it (s:AskReviewDiff below)
      \ 'review':    {'model': 'claude-opus-5-5', 'effort': 'medium',
      \               'system_prompt': 'You review code for a programmer in Vim. You are given the file''s '
      \                 . 'uncommitted changes as a git diff (if any) and the lines they selected. The answer is '
      \                 . 'read in a popup: no preamble, bullets grouped by severity (bugs, then issues, then '
      \                 . 'style), citing line numbers, light Markdown, as long as needed. If something cannot be '
      \                 . 'known from the code shown, say so instead of guessing.',
      \               'prompt': 'I am doing a code review. Please review this file''s additions (the diff) and the '
      \                 . 'selected lines. How is the code? Is it clean? Point out potential bugs and any issues '
      \                 . 'you see, and suggest changes or improvements.'},
      \ }
function! s:AskReviewDiff(sel) abort
  if a:sel.prompt !=# 'review' || a:sel.file ==# ''
    return {}
  endif
  let diff = systemlist('git -C ' . shellescape(fnamemodify(a:sel.file, ':h'))
        \ . ' diff HEAD -- ' . shellescape(a:sel.file))
  return v:shell_error || empty(diff) ? {} : {'name': 'diff', 'lines': ['Uncommitted changes:', '```diff'] + diff + ['```']}
endfunction
let g:ask_context_providers = get(g:, 'ask_context_providers', [])
if index(g:ask_context_providers, function('s:AskReviewDiff')) < 0
  call add(g:ask_context_providers, function('s:AskReviewDiff'))
endif
xnoremap <silent> <leader>R :Ask -review<CR>
let g:ask_default = 'explain'                 " <leader>i
let g:ask_model = 'claude-opus-5-5'
let g:ask_effort = 'low'
" <leader>I searches the git repo of the file; a CMSSW checkout is sparse, so also the release
let g:ask_search_dirs = filter([$CMSSW_RELEASE_BASE . '/src', $CMSSW_FULL_RELEASE_BASE . '/src'], 'isdirectory(v:val)')
" offered by :AskModel
let g:ask_models = ['claude-opus-5-5', 'claude-sonnet-5-5', 'claude-haiku-5-5', 'claude-fable-5-1']

" -- Path completion that resolves variables -------------------------------------
" Type a path containing / (any file type) and that directory's entries pop up.
" Before listing it substitutes ${VAR} {VAR} $VAR (last `set(VAR value` or
" `VAR = value` above the cursor, else the environment), $ENV{VAR}, ~, and CMake's
" CMAKE_CURRENT_SOURCE_DIR / CMAKE_CURRENT_LIST_DIR (this file's dir) and
" CMAKE_SOURCE_DIR / PROJECT_SOURCE_DIR (topmost CMakeLists.txt above it).
" Relative paths start from this file's directory. So after
"   set(CMS_EXT /cvmfs/cms.cern.ch/el8_amd64_gcc13/external)
" typing ${CMS_EXT}/alpaka/2. lists the real alpaka 2.x directories.
function! s:PathVar(name, envonly) abort
  if a:name =~# '^CMAKE_CURRENT_\%(SOURCE\|LIST\)_DIR$'
    return expand('%:p:h')
  elseif a:name =~# '^\%(CMAKE\|PROJECT\)_SOURCE_DIR$'
    let l:dir = expand('%:p:h')
    while l:dir !=# '/' && filereadable(fnamemodify(l:dir, ':h') . '/CMakeLists.txt')
      let l:dir = fnamemodify(l:dir, ':h')
    endwhile
    return l:dir
  endif
  let l:val = v:null
  if !a:envonly
    let l:pat = '\%(\<[Ss][Ee][Tt]\s*(\s*' . a:name . '\s\+\|\<' . a:name
          \ . '\s*:\==\s*\)["'']\=\zs[^"''[:space:])]\+'
    for l:line in getline(1, line('.') - 1)
      let l:m = matchstr(l:line, l:pat)
      if !empty(l:m) | let l:val = l:m | endif
    endfor
  endif
  return l:val is v:null ? getenv(a:name) : l:val   " v:null if unknown
endfunction

function! s:PathExpand(path) abort
  let l:p = a:path
  for _ in range(20)   " values can use other variables; the cap stops set(A ${A}/x)
    let l:m = matchlist(l:p, '\$\(ENV\)\={\(\h\w*\)}\|\$\(\h\w*\)\|{\(\h\w*\)}')
    if empty(l:m) | return l:p | endif
    let l:val = s:PathVar(l:m[2] . l:m[3] . l:m[4], l:m[1] ==# 'ENV')
    if l:val is v:null | return v:null | endif
    let l:i = stridx(l:p, l:m[0])
    let l:p = strpart(l:p, 0, l:i) . l:val . strpart(l:p, l:i + len(l:m[0]))
  endfor
  return v:null
endfunction

function! s:PathComplete(opt, ctx) abort
  let l:tok = matchstr(a:ctx.typed, '[^[:space:]"''(),=;:]*$')
  let l:base = matchstr(l:tok, '[^/]*$')
  let l:dir = l:tok =~# '/' ? s:PathExpand(l:tok[: -len(l:base) - 1]) : v:null
  let l:items = []
  if l:dir isnot v:null
    if l:dir =~# '^\~/' | let l:dir = $HOME . l:dir[1:] | endif
    if l:dir !~# '^/' | let l:dir = expand('%:p:h') . '/' . l:dir | endif
    for l:e in isdirectory(l:dir) ? readdirex(l:dir) : []
      if l:e.name[0] ==# '.' && l:base[0] !=# '.' | continue | endif
      let l:isdir = l:e.type =~# '^\%(dir\|linkd\|junction\)$'
      call add(l:items, {'word': l:e.name . (l:isdir ? '/' : ''),
            \ 'menu': l:isdir ? '[dir]' : '[file]'})
    endfor
  endif
  call asyncomplete#complete(a:opt.name, a:ctx, a:ctx.col - len(l:base), l:items)
endfunction

" asyncomplete only re-asks on keyword chars, so also trigger on . - + (2.0.0-abc)
" Replaces asyncomplete's filter (same fuzzy match) so that when real path entries
" match, only those show; otherwise the LSP's hundreds of words bury them
function! s:Preprocess(opts, matches) abort
  let l:found = {}
  for [l:name, l:src] in items(a:matches)
    let l:base = a:opts.typed[l:src.startcol - 1 :]
    let l:items = empty(l:base) ? l:src.items : matchfuzzy(l:src.items, l:base, {'key': 'word'})
    if !empty(l:items) | let l:found[l:name] = [l:src.startcol, l:items] | endif
  endfor
  if has_key(l:found, 'path') | let l:found = {'path': l:found.path} | endif
  let a:opts.startcol = min(map(values(l:found), 'v:val[0]'))
  call asyncomplete#preprocess_complete(a:opts, flatten(map(values(l:found), 'v:val[1]')))
endfunction
let g:asyncomplete_preprocessor = [function('s:Preprocess')]

augroup vimrc_path
  autocmd!
  autocmd User asyncomplete_setup call asyncomplete#register_source({'name': 'path',
        \ 'allowlist': ['*'], 'priority': 10, 'triggers': {'*': ['/', '.', '-', '+']},
        \ 'completor': function('s:PathComplete')})
augroup END
