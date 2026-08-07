# dotfiles

neovim + vim + tmux + bash config, tuned for CMSSW / performance work on CPU & GPU code.

## Layout

| file                  | links to           |
|-----------------------|--------------------|
| `vimrc`               | `~/.vimrc`         |
| `tmux.conf`           | `~/.tmux.conf`     |
| `bashrc`              | `~/.bashrc`        |
| `gitconfig`           | `~/.gitconfig`     |
| `config/nvim/`        | `~/.config/nvim/`  |
| `config/tmux/`        | `~/.config/tmux/`  |
| `config/git/`         | `~/.config/git/`   |

Plugin managers (lazy.nvim, vim-plug, TPM) and the plugins/servers they fetch
(`~/.local/share/nvim/lazy`, `~/.vim/plugged`, `~/.tmux/plugins`) are *not* stored
here - they're bootstrapped by `install.sh` and managed by the tools themselves,
same idea as not committing `node_modules`.

## Neovim

Neovim is the primary editor now (`config/nvim/`, lazy.nvim). It reuses the whole
vimrc keymap vocabulary, plus native LSP, telescope, oil, gitsigns/diffview.

- **Build**: neovim's official binaries need a newer glibc than this el8 box has,
  so nvim is built from source (gcc-toolset-13) into `~/.local/bin/nvim`; the build
  tree lives on `/data/mmarriot/tools/neovim` (off the 10 GB AFS quota). Update with
  `cd ~/src/neovim && git pull && make CMAKE_INSTALL_PREFIX=$HOME/.local && make install`.
- **C++ LSP**: clangd/clang-format/clang-tidy come from **`cmsenv`** (CVMFS, el8-built,
  version-matched to the compiler). *Launch nvim from inside a cmsenv* and C++ LSP
  attaches automatically; outside one it stays quiet. No Mason. Generate flags with
  `scram build -j4 compile_commands.json`.
- **Python LSP**: pyright (npm) + ruff (static binary).
- **CLI tools** (`ripgrep`, `fd`, `lazygit`, `ruff`, `viu`): single static musl
  binaries on `/data/mmarriot/tools/bin`, symlinked into `~/.local/bin` - no conda
  (conda dependency trees blow the AFS quota). `install.sh` fetches the latest of each.
- **The CMSSW machinery** (`:Scope` workspace, `gf`/`<leader>cf` path resolver,
  `<C-x><C-u>` path completion, `<leader>tt` terminal) is the old vimscript, sourced
  verbatim from `config/nvim/cmssw.vim`.
- **Images over ssh**: `viu <file.png>` in a tmux pane. Ghostty speaks the kitty
  graphics protocol; tmux passes it through (`allow-passthrough on`).

Keymaps mirror the Vim tables below. New/changed in nvim: `<leader>e`/`-` open **oil**
(edit the filesystem as a buffer); `<leader>i` symbol outline (aerial); `<leader>gv`
diffview (cross-branch diff); `<leader>fr` telescope ripgrep; `<leader>ce` Trouble
diagnostics; `which-key` shows leader mappings as you type.

> After pulling these changes, reload tmux (`prefix + r`) once so truecolor
> (`terminal-features RGB`) is active - gruvbox needs it.

## Install (new machine)

```sh
git clone <this-repo-url> ~/dotfiles
~/dotfiles/install.sh
vim +PlugInstall +qa
tmux new -d && tmux send-keys -t 0 'true' Enter  # then prefix+I inside a real session
```

## Shortcuts

Vim leader is **space**. Tmux prefix is **Ctrl-a**.

### Vim - files & explorer
| key            | action |
|----------------|--------|
| `<leader>e`    | toggle tree sidebar (netrw) |
| `<leader>E`    | open sidebar at current file's directory |
| `-`            | (in any buffer) jump into netrw at current file's dir |
| `v` / `Ctrl-v` | (in netrw) open file under cursor in a vertical split |
| `o`            | (in netrw) open under cursor in a horizontal split |
| `%` / `d`      | (in netrw) new file / new directory |
| `R` / `D`      | (in netrw) rename / delete |
| `<leader>ff`   | fuzzy find files (fzf) |
| `<leader>fg`   | fuzzy find git-tracked files |
| `<leader>fr`   | ripgrep search |
| `<leader>fb`   | fuzzy find open buffers |
| `<leader>fc`   | fuzzy find files under `$CMSSW_BASE/src` |
| `<leader>fC`   | ripgrep scoped to `$CMSSW_BASE/src` (.cc/.h/.py) |
| `<leader>cf`   | open CMSSW-relative path/header under cursor |
| `<leader>cv`   | same, in a vertical split |
| `gf`           | open file under cursor (path-aware, incl. CMSSW paths) |

### Vim - windows, buffers, terminal
| key                | action |
|--------------------|--------|
| `<leader>a/s/d/w`  | move to window left/down/right/up |
| `<leader>=`        | equalize window sizes |
| `<leader>tt`       | toggle a terminal split (open / hide / reopen same session) |
| `Esc` (in terminal)| back to normal mode |
| `]b` / `[b`        | next / previous buffer |
| `<leader>bd`       | delete buffer |
| `<leader>x`        | save |
| `<leader>es`       | quit window |

### Vim - code (LSP: clangd for C++, pyright for Python)
| key          | action |
|--------------|--------|
| `gd`         | go to definition |
| `gr`         | references |
| `gi`         | implementation |
| `K`          | hover docs |
| `<leader>rn` | rename symbol |
| `<leader>ca` | code action |
| `]e` / `[e`  | next / previous diagnostic |
| `Tab`/`S-Tab`| cycle completion popup |
| `Ctrl-Space` | force completion popup |

First-time per machine: open a `.cc`/`.py` file and run `:LspInstallServer`; for C++
also run `scram build -j4 compile_commands.json` so clangd sees your flags.

### Vim - git (fugitive + gitgutter)
| key          | action |
|--------------|--------|
| `<leader>gs` | `:Git` status |
| `<leader>gd` | diff split |
| `<leader>gb` | blame |
| `<leader>gc` | commit |
| `<leader>gp` / `gP` | push / pull |
| `]h` / `[h`  | next / previous git hunk |
| `<leader>hs` / `hu` | stage / undo hunk |

### Bash - command line (vi mode)

The prompt shows which mode you are in: green `[i]` insert (bar cursor), pink `[n]`
normal (block cursor). All the fzf widgets below work in both modes.

| key            | action |
|----------------|--------|
| `Esc` or `jk`  | leave insert mode; then `w` `b` `e` `0` `$` `f` `t`, `ci"`, `dw`, `yy`/`p`, `u` as in vim |
| `v` (normal)   | open the current command line in `$EDITOR`; saving runs it |
| `Up` / `Down`  | history search on what you have already typed |
| `Ctrl-a`       | start of line (kept from emacs mode) |
| `Ctrl-r`       | fzf history search |
| `Ctrl-f` / `Ctrl-e` | fzf under `$CMSSW_BASE/src` / fzf-open in vim |

### Tmux
| key                  | action |
|----------------------|--------|
| `prefix -` / `\|`     | split horizontal / vertical (in current dir) |
| `prefix c`           | new window (in current dir) |
| `prefix m`           | zoom/unzoom pane |
| `Ctrl-h/j/k/l`       | move between panes - forwarded into vim splits automatically |
| `Alt-h` / `Alt-l`    | previous / next window |
| `prefix S`           | switch session |
| `prefix N`           | new named session |
| `prefix M-1` / `M-2` | preset layouts (editor+terminal, side-by-side / stacked) |
| `Ctrl-double-click`  | resolve and open a file/path under the mouse in a new split |
| copy-mode `o`        | open the selected file:line in a new split |
| copy-mode `v`/`V`/`y`| select / select line / copy to system clipboard |
| `prefix I`           | install tmux plugins (TPM) |

### Clipboard (this box has no X server - ssh only)

Everything below reaches the **Mac's** system clipboard via OSC52 escape sequences sent
straight through ssh (through tmux's passthrough too, if you're in a session). Needs a
terminal that honours OSC52 - iTerm2, Alacritty, Kitty and WezTerm all do by default.

| where               | action |
|---------------------|--------|
| vim, any yank/delete| copies to system clipboard automatically |
| tmux copy-mode `y`  | copies selection to system clipboard |
| shell               | `<command> \| copy` (alias `pbcopy`) copies stdout |
