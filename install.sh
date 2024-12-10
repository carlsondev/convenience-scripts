#!/usr/bin/env bash

if ! command -v curl &> /dev/null
then
    echo "curl could not be found"
    exit 1
fi

echo "Installing ZSH"
sudo apt install zsh


echo "Changing the default shell to ZSH"
sudo chsh -s $(which zsh)

exec zsh

# Install Oh - My - Zsh
echo "Installing Oh-My-ZSH"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit $?

echo -e "export PATH=$HOME/bin:/usr/local/bin:$PATH\n$(cat ~/.zshrc)" > ~/.zshrc

# Set the theme to eastwood
sed -i 's/ZSH_THEME=.*/ZSH_THEME="eastwood"/' ~/.zshrc

echo "Downloading ZSH plugins"

sudo git clone --quiet https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || exit $?

sudo git clone --quiet https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting || exit $?

sed -i 's/plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

source ~/.zshrc && echo "Successfully Setup Zsh Env!" || exit $?

# Copy custom scripts

REPO_PATH=~/.con-scripts-repo

git clone --quiet https://github.com/carlsondev/convenience-scripts.git $REPO_PATH || exit $?

echo "Copying scripts to user bin"
chmod +x $REPO_PATH/scripts/* || exit $?
sudo cp -r $REPO_PATH/scripts/* /usr/local/bin/ || exit $?

echo "Successfully copied custom scripts to user bin"

rm -rf $REPO_PATH

# Install FZF
git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
~/.fzf/install --all

# Install VimPlug and FZF 
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

VIMRC="
call plug#begin()

Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

call plug#end()
"
echo "$VIMRC" >> ~/.vimrc

echo "\nInstalled FZF and VimPlug-Fzf! Run ':PlugInstall' inside vim to finish the installation"

echo "\nSuccessfully setup environment! Run \"chsh -s $(which zsh) && exec zsh && source ~/.zshrc\" to enter"






