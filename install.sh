#!/usr/bin/env bash

echo "Changing the default shell to ZSH"
chsh -s $(which zsh)

# Install Oh - My - Zsh
echo "Installing Oh-My-ZSH"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || exit $?

echo -e "export PATH=$HOME/bin:/usr/local/bin:$PATH\n$(cat ~/.zshrc)" > ~/.zshrc

# Set the theme to eastwood
sed -i 's/ZSH_THEME=.*/ZSH_THEME="eastwood"/' ~/.zshrc

echo "Downloading ZSH plugins"

git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions || exit $?

git clone https://github.com/zsh-users/zsh-syntax-highlighting.git $ZSH_CUSTOM/plugins/zsh-syntax-highlighting || exit $?

sed -i 's/plugins=.*/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' ~/.zshrc

source ~/.zshrc && echo "Successfully Setup Zsh Env!" || exit $?

# Copy custom scripts

REPO_PATH=~/.con-scripts-repo

git clone https://github.com/carlsondev/convenience-scripts.git $REPO_PATH || exit $?

echo "Copying scripts to user bin"
chmod +x $REPO_PATH/scripts/* || exit $?
sudo cp -r $REPO_PATH/scripts/* /usr/local/bin/ || exit $?

echo "Successfully copied custom scripts to user bin"





rm -rf $REPO_PATH






