#!/usr/bin/env bash
# Linux (apt) installer. Sets up zsh + oh-my-zsh, installs the custom scripts, fzf, and vim-plug.
# Safe to re-run: each step skips work that is already done.

set -euo pipefail

REPO_URL="https://github.com/carlsondev/convenience-scripts.git"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

info() { printf '\n==> %s\n' "$*"; }

for cmd in curl sudo apt-get; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "$cmd could not be found" >&2
        exit 1
    fi
done

# Install ZSH (and git, which everything below needs)
info "Installing ZSH and git"
sudo apt-get update -qq
sudo apt-get install -y zsh git

info "Changing the default shell to ZSH"
ZSH_PATH="$(command -v zsh)"
if [ "$(getent passwd "$USER" | cut -d: -f7)" != "$ZSH_PATH" ]; then
    sudo chsh -s "$ZSH_PATH" "$USER"
fi

# Install Oh-My-Zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    info "Installing Oh-My-ZSH"
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

PATH_LINE='export PATH=$HOME/bin:/usr/local/bin:$PATH'
if ! grep -qxF "$PATH_LINE" ~/.zshrc; then
    printf '%s\n%s\n' "$PATH_LINE" "$(cat ~/.zshrc)" > ~/.zshrc
fi

# Set the theme to eastwood
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="eastwood"/' ~/.zshrc

info "Downloading ZSH plugins"
clone_if_missing() {
    [ -d "$2" ] || git clone --quiet --depth 1 "$1" "$2"
}
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

sed -i 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Copy custom scripts
info "Copying scripts to /usr/local/bin"
REPO_PATH="$(mktemp -d)"
trap 'rm -rf "$REPO_PATH"' EXIT
git clone --quiet --depth 1 "$REPO_URL" "$REPO_PATH"
sudo install -m 755 "$REPO_PATH"/scripts/* /usr/local/bin/

# Install FZF
info "Installing FZF"
clone_if_missing https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Install VimPlug and FZF
info "Installing vim-plug"
curl -fsSLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

if ! grep -qF "junegunn/fzf.vim" ~/.vimrc 2> /dev/null; then
    cat >> ~/.vimrc << 'EOF'

call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()
EOF
fi

info "Installed FZF and VimPlug-Fzf! Run ':PlugInstall' inside vim to finish the installation"
info "Successfully set up environment! Log out and back in (or run 'exec zsh') to start using it"
