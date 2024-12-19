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

# Check if we are root
[ "$(id -u)" -eq 0 ] && IS_ROOT=true || IS_ROOT=false

# Function to check if a given package is installed
is_package_installed() {
    package="$1"
    case "$package_manager" in
        apt|pkg)
            dpkg-query -W -f='${Status}' "$package" 2>/dev/null
            ;;
        rpm-ostree|yum|dnf)
            rpm -q "$package" 2>/dev/null
            ;;
        pamac|pacman)
            pacman -Q "$package" 2>/dev/null
            ;;
    esac
}

dot() {
    GIT_DIR=$HOME/.dot/.git/ GIT_WORK_TREE=$HOME /usr/bin/git "$@"
}

echo "Cloning dotfiles to ${HOME}/.dot"
git clone --no-checkout https://windweaver828@bitbucket.org/windweaver828/dotfiles.git $HOME/.dot || { echo "Cloning failed..."; exit 1; }
dot checkout
echo "Cloning dotfiles submodules"
dot submodule update --init --recursive --force >/dev/null 2>&1
dot config --local status.showUntrackedFiles no

# Install oh-my-zsh and custom files
rm -rf $HOME/.oh-my-zsh/custom
ln -s $HOME/.dotfiles/oh-my-zsh-custom $HOME/.oh-my-zsh/custom

# Check and install recommended programs
dependencies=("curl" "zsh" "tmux" "git" "lsd" "bat" "fontconfig" "ncurses-term" "neovim")

if command -v pkg >/dev/null 2>&1; then
    package_manager="pkg"
    install_command="pkg install -y ${dependencies[@]}"
elif command -v ap >/dev/null 2>&1; then
    package_manager="apt"
    install_command="apt install -y ${dependencies[@]}"
elif command -v rpm-ostree >/dev/null 2>&1; then
    package_manager="rpm-ostree"
    dependencies+=("glibc-langpack-en" "gcc")
    install_command="rpm-ostree install -y ${dependencies[@]}"
elif command -v pamac >/dev/null 2>&1; then
    package_manager="pamac"
    install_command="pamac install -y ${dependencies[@]}"
fi
# Add sudo to install_command if we aren't root
if [[ -n ${install_command} ]]; then
    if ! ${IS_ROOT}; then
        install_command="sudo ${install_command}"
    fi
    # Run the install command
    ${install_command}
else
    echo "No supported package manager found, you will have to install the below dependencies manually"
    echo ${dependencies}
fi

# Determine which packages are not installed still
not_installed=()
for package in "${dependencies[@]}"; do
    [[ -n $(is_package_installed ${package}) ]] || not_installed+=("${package}")
done
if [[ -n ${not_installed} ]]; then
    echo "Failed to install: ${not_installed[@]}"
fi

# Install FiraCode Fonts
if [[ ${package_manager} == "pkg" ]]; then
    [[ -d $HOME/.termux ]] || mkdir -p $HOME/.termux
    cp $HOME/.dotfiles/FiraCodeNerdFont/FiraCodeNerdFont-Regular.ttf $HOME/.termux/font.ttf
else
    if [[ -n $(command -v fc-cache 2>/dev/null) ]]; then
        if [[ -z $(fc-list | grep -i "firacode") ]]; then
            if [ -d /usr/local/share/fonts ]; then
                echo "Installing FiraCode NerdFonts"
                if ${IS_ROOT}; then
                    cp $HOME/.dotfiles/FiraCodeNerdFont/*.ttf /usr/local/share/fonts/
                else
                    sudo cp $HOME/.dotfiles/FiraCodeNerdFont/*.ttf /usr/local/share/fonts/
                fi
                fc-cache -fv >/dev/null 2>&1
            else
                echo "/usr/local/share/fonts not found, you will need to install the FiraCodeNerdFont fonts manually"
            fi
        fi
    else
        echo "fc-cache not found, you will need to install the FiraCodeNerdFont fonts manually"
    fi
fi

# Open and close nvim to install lazy and all plugins
nvim --headless -c 'qa' >/dev/null 2>&1

echo "Installation Complete"
exec zsh
