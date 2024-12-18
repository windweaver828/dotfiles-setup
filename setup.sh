#!/bin/bash

# Delete all the dotfiles
cd $HOME
rm -rf .dot .dotfiles .zsh_history .zshrc .zcompdump* .tmux .tmux.conf .oh-my-zsh .pylintrc .gitignore .git-credentials .gitconfig .gitmodules .config/lsd .config/nvim .local/share/nvim

if [[ ${1} == "clean" ]]; then
    echo "Cleaning up dev environment"
    SCRIPT_DIR=$(dirname "$(realpath "$0")")
    if [ -d /mnt/c/Users/Keith ]; then
        echo "Showershop detected, removing extra files"
        cd "$HOME"
        rm -rf .viminfo* .zcompdump* .zsh_history projects/.git showershop/.git brandisgarage
        cd /mnt/c/Users/Keith/
        rm -rf .gitconfig .git-credentials passwords.json Documents/Projects/passwords.json
    fi
    rm -rf "$SCRIPT_DIR"
    echo "Cleanup complete"
    exit
fi

echo "Setting up dev environment"

dot() {
    GIT_DIR=$HOME/.dot/.git/ GIT_WORK_TREE=$HOME /usr/bin/git "$@"
}

if [[ ! -e $HOME/.dot ]]; then
    echo "Cloning dotfiles to ${HOME}/.dot"
    git clone --no-checkout https://windweaver828@bitbucket.org/windweaver828/dotfiles.git $HOME/.dot >/dev/null 2>&1
    dot checkout
    echo "Cloning dotfiles submodules"
    dot submodule update --init --recursive --force >/dev/null 2>&1
    dot config --local status.showUntrackedFiles no
fi

# Install oh-my-zsh and custom files
rm -rf $HOME/.oh-my-zsh/custom
ln -s $HOME/.dotfiles/oh-my-zsh-custom $HOME/.oh-my-zsh/custom

# List of packages needed to be installed
dependencies=("curl zsh tmux git lsd bat ncurses-term neovim")
IFS=' ' read -ra dependencies <<< $dependencies # convert to array
need_install=""
# If apt available, install dependencies
if [[ -n $(which apt) ]]; then
    echo "Found apt - checking and installing recommended packages"
    for package in "${dependencies[@]}"; do
        if ! dpkg -l | grep -q "^ii  $package "; then
            need_install+="$package ";
        fi
    done
    if [[ -n ${need_install} ]]; then
        echo "Installing packages: ${need_install}"
        sudo apt update >/dev/null 2>&1
        sudo apt install -y ${need_install} >/dev/null 2>&1
    else
        echo "No packages missing"
    fi
    if [[ -z $(which lsd) ]]; then
        echo "Failed to install lsd, install manually"
        echo "https://github.com/lsd-rs/lsd/releases"
    fi
else
    echo "System does not use apt, you will need to ensure packages are installed manually"
    echo ${dependencies}
fi

# Install FiraCode Fonts
if [[ -n $(which fc-cache) ]]; then
    if [[ -z $(fc-list | grep -i "firacode") ]]; then
        if [ -d /usr/local/share/fonts ]; then
            echo "Installing FiraCode NerdFonts"
            cp $HOME/.dotfiles/FiraCodeNerdFont/*.ttf /usr/local/share/fonts/
            fc-cache -fv >/dev/null 2>&1
        else
            echo "/usr/local/share/fonts not found, you will need to install the FiraCodeNerdFont fonts manually"
        fi
    fi
else
    echo "fc-cache not found, you will need to install the FiraCodeNerdFont fonts manually"
fi

# Open and close nvim to install lazy and all plugins
nvim --headless -c 'qa' >/dev/null 2>&1

echo "Installation Complete"
exec zsh
