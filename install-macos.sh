#!/usr/bin/env bash
# macOS installer. Sets up zsh + oh-my-zsh, installs the custom scripts, fzf, and vim-plug.
# Safe to re-run: each step skips work that is already done.
# Written for the stock /bin/bash (3.2) and BSD tools that ship with macOS.

set -euo pipefail

REPO_URL="https://github.com/carlsondev/convenience-scripts.git"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

info() { printf '\n==> %s\n' "$*"; }

for cmd in curl sudo; do
    if ! command -v "$cmd" &> /dev/null; then
        echo "$cmd could not be found" >&2
        exit 1
    fi
done

# Ask for the password once up front instead of partway through
info "Requesting sudo access"
sudo -v

# git ships with the Xcode Command Line Tools; /usr/bin/git is only a stub without them
if ! xcode-select -p &> /dev/null; then
    info "Installing Xcode Command Line Tools (finish the dialog that pops up)"
    xcode-select --install || true
    until xcode-select -p &> /dev/null; do
        sleep 5
    done
fi

# zsh ships with macOS (/bin/zsh), so just make it the login shell
info "Changing the default shell to ZSH"
ZSH_PATH="/bin/zsh"
if [ "$(dscl . -read "/Users/$USER" UserShell | awk '{print $2}')" != "$ZSH_PATH" ]; then
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

# Set the theme to eastwood (BSD sed needs an explicit empty backup suffix)
sed -i '' 's/^ZSH_THEME=.*/ZSH_THEME="eastwood"/' ~/.zshrc

info "Downloading ZSH plugins"
clone_if_missing() {
    [ -d "$2" ] || git clone --quiet --depth 1 "$1" "$2"
}
clone_if_missing https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
clone_if_missing https://github.com/zsh-users/zsh-syntax-highlighting.git "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"

sed -i '' 's/^plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

# Copy custom scripts (/usr/local/bin doesn't exist by default on Apple Silicon)
info "Copying scripts to /usr/local/bin"
REPO_PATH="$(mktemp -d)"
trap 'rm -rf "$REPO_PATH"' EXIT
git clone --quiet --depth 1 "$REPO_URL" "$REPO_PATH"
sudo mkdir -p /usr/local/bin
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
info "Successfully set up environment! Open a new terminal (or run 'exec zsh') to start using it"
