" ==============================================================================
"  cmssw.vim - CMSSW-specific machinery ported verbatim from the old ~/.vimrc.
"
"  Sourced from init.lua. These are pure vimscript with no plugin dependencies,
"  so they run unchanged in neovim. The dirvish/fzf-coupled halves of the old
"  Scope system (the listing + scoped pickers) are reimplemented in Lua on top
"  of oil + telescope (see lua/plugins/telescope.lua); the state machine below
"  (:Scope / :ScopeClear / g:scope_dirs) is shared by both.
" ==============================================================================


" ==============================================================================
"  SCOPED WORKSPACE  (:Scope - work on a chosen subset of a huge tree)
"
"    :Scope L1Trigger/L1THGCal DataFormats/L1THGCal   set the working set
"    :Scope        show the current working set
"    :ScopeClear   back to seeing everything
"
"  While a scope is set, <leader>ff / <leader>fr (telescope) narrow to it.
" ==============================================================================

let g:scope_dirs = get(g:, 'scope_dirs', [])

function! s:ResolveScopeDir(arg) abort
    if isdirectory(expand(a:arg))
        return expand(a:arg)
    endif
    if !empty($CMSSW_BASE) && isdirectory($CMSSW_BASE . '/src/' . a:arg)
        return $CMSSW_BASE . '/src/' . a:arg
    endif
    return ''
endfunction

function! s:SetScope(args) abort
    if empty(a:args)
        echo empty(g:scope_dirs) ? 'No scope set  (:Scope dir1 dir2 ...)'
                                \ : 'Scope: ' . join(g:scope_dirs, '  ')
        return
    endif
    let dirs = []
    for arg in a:args
        let dir = s:ResolveScopeDir(arg)
        if empty(dir)
            echohl WarningMsg
            echomsg 'Not a directory (checked cwd and $CMSSW_BASE/src): ' . arg
            echohl None
        else
            call add(dirs, substitute(dir, '/$', '', ''))
        endif
    endfor
    if empty(dirs) | return | endif      " nothing resolved - keep the old scope
    let g:scope_dirs = dirs
    echo 'Scope: ' . join(g:scope_dirs, '  ')
endfunction

function! s:ScopeComplete(lead, line, pos) abort
    let out = glob(a:lead . '*/', 1, 1)
    if !empty($CMSSW_BASE)
        let src = $CMSSW_BASE . '/src/'
        let out += map(glob(src . a:lead . '*/', 1, 1), 'strpart(v:val, len(src))')
    endif
    return map(out, "substitute(v:val, '/$', '', '')")
endfunction

command! -nargs=* -complete=customlist,s:ScopeComplete Scope call s:SetScope([<f-args>])
command! ScopeClear let g:scope_dirs = [] | echo 'Scope cleared'


" ==============================================================================
"  TERMINAL  (the toggle itself is the floating one in lua/config/terminal.lua
"  - <leader>t. These are generic terminal-mode conveniences that apply
"  regardless of how the terminal window got there.)
"
"    <Esc>           exit terminal insert mode back to normal
"    <leader>w/d/a   navigate out of the terminal pane like any window
" ==============================================================================

tnoremap <Esc>      <C-\><C-n>
tnoremap <leader>w  <C-w>k
tnoremap <leader>d  <C-w>l
tnoremap <leader>a  <C-w>h


" ==============================================================================
"  CMSSW PATH INTEGRATION
"
"    gf            open the header/path under the cursor (release area too)
"    <leader>cf    open CMSSW-relative path under cursor
"    <leader>cv    same, in a vertical split
"    <C-x><C-u>    complete CMSSW slash/dotted paths (works with no compile db)
" ==============================================================================

function! s:AddCMSSWPaths()
    let cmssw = $CMSSW_BASE
    if empty(cmssw) | return | endif
    execute 'set path+=' . cmssw . '/src/**'
    execute 'set path+=' . cmssw . '/lib/**'
    " Release area too, so gf works on headers of packages you haven't checked
    " out. Plain /src, no ** - includes are already Package/Sub/... relative to
    " src, and recursing into a full release on cvmfs would take forever.
    for base in [$CMSSW_FULL_RELEASE_BASE, $CMSSW_RELEASE_BASE]
        if !empty(base) | execute 'set path+=' . base . '/src' | endif
    endfor
endfunction
call s:AddCMSSWPaths()

command! CMSSWRefresh call s:AddCMSSWPaths() | echo "CMSSW paths refreshed"

nnoremap <leader>cf :call OpenCMSSWPath()<CR>
nnoremap <leader>cv :call OpenCMSSWPathSplit()<CR>

function! OpenCMSSWPath()
    let token = expand('<cfile>')
    if filereadable(token) || isdirectory(token)
        execute 'edit ' . fnameescape(token) | return
    endif
    " Direct hit in the local area first, then the release area
    for base in [$CMSSW_BASE, $CMSSW_FULL_RELEASE_BASE, $CMSSW_RELEASE_BASE]
        if empty(base) | continue | endif
        let full = base . '/src/' . token
        if filereadable(full) || isdirectory(full)
            execute 'edit ' . fnameescape(full) | return
        endif
    endfor
    " Basename search as a fallback - local checkout only (a ** crawl of the
    " full release on cvmfs would hang)
    if !empty($CMSSW_BASE)
        let hits = globpath($CMSSW_BASE . '/src', '**/' . fnamemodify(token, ':t'), 0, 1)
        if !empty(hits)
            if len(hits) == 1
                execute 'edit ' . fnameescape(hits[0])
            else
                call setqflist(map(copy(hits), '{"filename": v:val, "lnum": 1}'))
                copen
            endif
            return
        endif
    endif
    echo "Not found: " . token
endfunction

function! OpenCMSSWPathSplit()
    let token = expand('<cfile>')
    let cmssw = $CMSSW_BASE
    if filereadable(token)
        let full = token
    elseif !empty(cmssw) && filereadable(cmssw . '/src/' . token)
        let full = cmssw . '/src/' . token
    else
        let full = ''
    endif
    if empty(full) | echo "Not found: " . token | return | endif
    execute 'vsplit ' . fnameescape(full)
endfunction

" -- CMSSW path completion (insert mode: <C-x><C-u>) ---------------------------
function! CmsswPathComplete(findstart, base) abort
    if a:findstart
        let line  = getline('.')
        let start = col('.') - 1
        while start > 0 && line[start - 1] =~# '[A-Za-z0-9_./-]'
            let start -= 1
        endwhile
        return start
    endif

    let dotted = &filetype ==# 'python' && a:base !~# '/'
    let token  = dotted ? substitute(a:base, '\.', '/', 'g') : a:base

    let roots = []
    for base in [$CMSSW_BASE, $CMSSW_FULL_RELEASE_BASE, $CMSSW_RELEASE_BASE]
        if empty(base) | continue | endif
        call add(roots, [base . '/src', 'src'])
        if dotted && !empty($SCRAM_ARCH)
            call add(roots, [base . '/cfipython/' . $SCRAM_ARCH, 'cfi'])
        endif
    endfor

    let out  = []
    let seen = {}
    for [root, style] in roots
        if !isdirectory(root) | continue | endif
        let pat = token
        if dotted && style ==# 'src'
            let comps = split(token, '/', 1)
            if len(comps) >= 3
                let pat = comps[0] . '/' . comps[1] . '/python/' . join(comps[2:], '/')
            endif
        endif
        for hit in glob(root . '/' . pat . '*', 1, 1)
            let rel   = strpart(hit, len(root) + 1)
            let isdir = isdirectory(hit)
            if dotted
                if !isdir && rel !~# '\.py$' | continue | endif
                let rel  = substitute(rel, '/python/', '/', '')
                let rel  = substitute(rel, '\.py$', '', '')
                let word = substitute(rel, '/', '.', 'g') . (isdir ? '.' : '')
            else
                let word = rel . (isdir ? '/' : '')
            endif
            if has_key(seen, word) | continue | endif
            let seen[word] = 1
            call add(out, {'word': word, 'menu': isdir ? '/' : ''})
        endfor
    endfor
    return sort(out, {a, b -> a.word ==# b.word ? 0 : a.word ># b.word ? 1 : -1})
endfunction

set completefunc=CmsswPathComplete


" ==============================================================================
"  AUTOCOMMANDS
" ==============================================================================

augroup vimrc_misc
    autocmd!
    " Strip trailing whitespace on save
    autocmd BufWritePre *.cc,*.h,*.cpp,*.py,*.vim,*.cfg :%s/\s\+$//e
    " Return to last cursor position when reopening a file
    autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
    " Refresh CMSSW paths if CMSSW_BASE changes (e.g. after cmsenv in a term pane)
    autocmd ShellCmdPost * call s:AddCMSSWPaths()
augroup END

" Build/run helpers for C++ (project-local run.sh)
autocmd FileType cpp nnoremap <buffer> <F5> :w <bar> !./run.sh<CR>
autocmd FileType cpp nnoremap <buffer> <F7> :w <bar> !./run.sh copy<CR>
autocmd FileType cpp nnoremap <buffer> <F6> :w <bar> !./run.sh reset<CR>

" Markdown: Tab/S-Tab indent list items (insert + normal)
autocmd FileType markdown inoremap <buffer> <Tab>   <Esc>>>A
autocmd FileType markdown inoremap <buffer> <S-Tab> <Esc><<A
autocmd FileType markdown nnoremap <buffer> <Tab>   >>
autocmd FileType markdown nnoremap <buffer> <S-Tab> <<
