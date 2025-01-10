#!/bin/bash

# Print the password to the screen before deleting everything, if available
if [[ -e $HOME/.git-credentials ]] then
  cat $HOME/.git-credentials
fi

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

echo "Setting up environment"

dot() {
    GIT_DIR=$HOME/.dot/.git/ GIT_WORK_TREE=$HOME /usr/bin/git "$@"
}

echo "Cloning dotfiles to ${HOME}/.dot"
git clone --no-checkout https://windweaver828@bitbucket.org/windweaver828/dotfiles.git $HOME/.dot || { echo "Cloning failed..."; exit 1; }
dot checkout
echo "Cloning dotfiles submodules"
dot submodule update --init --recursive --force >/dev/null 2>&1
dot config --local status.showUntrackedFiles no
# Stop checking .git-credentials for changes
dot update-index --assume-unchanged $HOME/.git-credentials

# List of packages needed to be installed
dependencies=("curl fontconfig git") # General required tools
dependencies+=(" bat lsd ncurses-term tmux zsh") # For shell environment
dependencies+=(" fd-find neovim ripgrep") # For neovim & plugins
IFS=' ' read -ra dependencies <<< $dependencies # convert to array
need_install=()
# If apt available, install dependencies
if [[ -n $(command -v apt 2>/dev/null) ]]; then
    for package in "${dependencies[@]}"; do
        if ! dpkg -l | grep -q "^ii  ${package} "; then
            need_install+=("${package}");
        fi
    done
    if [[ -n ${need_install} ]]; then
        echo "Installing packages via apt: ${need_install[*]}"
        sudo apt update >/dev/null 2>&1
        sudo apt install -y ${need_install[@]} >/dev/null 2>&1
    fi
else
    echo "System does not use apt, you will need to ensure packages are installed manually"
    echo ${dependencies[@]}
fi

# Install pip dependencies
pip_dependencies=("pyright" "flake8" "black")
if [[ -n $(command -v pip) ]] then
  echo "Installing pip dependencies"
  pip install "${pip_dependencies[@]}" >/dev/null 2>&1
else
  echo "pip not found, you will need to install python pip and the following dependencies"
  echo "${pip_dependencies[*]}"
fi

# Install FiraCode Fonts
if [[ -n $(command -v fc-cache 2>/dev/null) ]]; then
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
