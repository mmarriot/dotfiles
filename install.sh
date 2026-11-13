#!/usr/bin/env bash
# ~/dotfiles/install.sh
#
# Symlinks these configs into place and bootstraps the vim/tmux plugin
# managers. Safe to re-run: existing real files get backed up once with a
# .bak suffix, correct symlinks are left alone.

set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
    local src="$DOTFILES/$1" dest="$HOME/$2"
    if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
        return
    fi
    if [[ -e "$dest" || -L "$dest" ]]; then
        echo "backing up existing $dest -> $dest.bak"
        mv "$dest" "$dest.bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -s "$src" "$dest"
    echo "linked $dest -> $src"
}

link vimrc        .vimrc
link tmux.conf     .tmux.conf
link bashrc        .bashrc
link gitconfig     .gitconfig
link config/tmux   .config/tmux
link config/git    .config/git
link config/clangd .config/clangd
link vim/colors    .vim/colors

# -- vim-plug --------------------------------------------------------------
if [[ ! -f "$HOME/.vim/autoload/plug.vim" ]]; then
    echo "installing vim-plug"
    curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

# -- tmux plugin manager (TPM) ----------------------------------------------
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
    echo "installing tpm"
    git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
fi

# -- command-line tools ------------------------------------------------------
# clangd/clang-format/clang-tidy come from `cmsenv` (CVMFS) - not installed here.
# These are single static (musl) binaries - no glibc dependency, no conda
# dependency trees (this AFS home has a 10 GB quota). Binaries live on /data
# (roomy) and are symlinked into ~/.local/bin so AFS usage stays near zero.
mkdir -p "$HOME/.local/bin"
TOOLS_BIN="/data/mmarriot/tools/bin"
mkdir -p "$TOOLS_BIN"

# latest musl/static asset URL for a github repo matching a grep pattern
gh_asset() {
    curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
        | grep -o '"browser_download_url": *"[^"]*"' \
        | sed 's/.*"\(https[^"]*\)"/\1/' | grep -E "$2" | head -1
}

install_static() {   # name  repo  asset-pattern  [tar-inner-path]
    local name="$1" repo="$2" pat="$3" inner="${4:-}"
    command -v "$name" >/dev/null 2>&1 && return
    local url; url="$(gh_asset "$repo" "$pat")"
    [[ -z "$url" ]] && { echo "  ! $name: no matching asset"; return; }
    echo "installing $name ($url)"
    local tmp; tmp="$(mktemp -d)"
    if [[ "$url" == *.tar.gz ]]; then
        curl -fsSL "$url" -o "$tmp/a.tgz" && tar -xzf "$tmp/a.tgz" -C "$tmp"
        local bin; bin="$(find "$tmp" -type f -name "$name" | head -1)"
        [[ -n "$bin" ]] && cp "$bin" "$TOOLS_BIN/$name"
    else
        curl -fsSL "$url" -o "$TOOLS_BIN/$name"
    fi
    rm -rf "$tmp"
    [[ -f "$TOOLS_BIN/$name" ]] && chmod +x "$TOOLS_BIN/$name" \
        && ln -sf "$TOOLS_BIN/$name" "$HOME/.local/bin/$name"
}

install_static ruff    astral-sh/ruff        'ruff-x86_64-unknown-linux-musl\.tar\.gz$'
install_static rg      BurntSushi/ripgrep    'x86_64-unknown-linux-musl\.tar\.gz$'
install_static fd      sharkdp/fd            'x86_64-unknown-linux-musl\.tar\.gz$'
install_static lazygit jesseduffield/lazygit 'inux_x86_64\.tar\.gz$'
install_static viu     atanunq/viu           'viu-x86_64-unknown-linux-musl$'

echo
echo "Done. Next steps:"
echo "  vim  -> :PlugInstall"
echo "  tmux -> prefix + I   (installs tmux plugins)"
echo "  images -> 'viu <file.png>' in a tmux pane (Ghostty kitty-protocol, over ssh)"
