#!/bin/bash

rm -rf $HOME/.dot

# Print the password to the screen before deleting everything, if it exists
if [[ -e $HOME/.git-credentials ]]; then
  cat $HOME/.git-credentials
fi

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
git clone --no-checkout https://github.com/windweaver828/dotfiles.git $HOME/.dot || {
  echo "Cloning failed..."
  exit 1
}
dot checkout -f
echo "Cloning dotfiles submodules"
dot submodule update --init --recursive --force >/dev/null 2>&1
dot config --local status.showUntrackedFiles no
# Stop checking .git-credentials for changes
dot update-index --assume-unchanged $HOME/.git-credentials

# Install Homebrew
if [[ -z $(command -v brew) ]]; then
  read -p "Homebrew is not installed. Do you want to install it? (y/n): " choice
  if [[ "$choice" == [Yy]* ]]; then
    echo "Installing Homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  else
    echo "Homebrew installation skipped."
  fi
fi

# List of packages needed to be installed
brew_installs=("npm" "rust" "neovim" "lazygit"
  "lsd" "fzf" "zoxide" "ripgrep" "nushell" "starship"
)

dependencies=(
  "curl" "git"                                # General required tools
  "pkg-config" "libssl-dev" "build-essential" # For homebrew/linuxbrew
  "ncurses-term" "tmux" "zsh"                 # For shell environment
  "make"                                      # For neovim lsps, ai
)

# Install FiraCode Fonts
if command -v fc-cache >/dev/null 2>&1; then
  if ! fc-list | grep -qi "firacode"; then
    FONT_DIR="$HOME/.local/share/fonts"
    if [ ! -d "$FONT_DIR" ]; then
      echo "Creating fonts directory at $FONT_DIR"
      mkdir -p "$FONT_DIR"
    fi
    echo "Installing FiraCode NerdFonts"
    for font in "$HOME/.dotfiles/FiraCodeNerdFont/"*.ttf; do
      cp "$font" "$FONT_DIR"
    done
    fc-cache -fv >/dev/null 2>&1
    if fc-list | grep -qi "firacode"; then
      echo "FiraCode NerdFonts installed successfully."
    else
      echo "Failed to install FiraCode NerdFonts. Please check manually."
    fi
  else
    echo "FiraCode NerdFonts are already installed."
  fi
else
  echo "fc-cache not found, you will need to install the FiraCodeNerdFont fonts manually"
fi

# Install any missing tmux plugins
$HOME/.tmux/plugins/tpm/bin/install_plugins >/dev/null

# Open and close nvim to install lazy and all plugins
nvim --headless -c 'qa' >/dev/null 2>&1

# Build the bat cache if possible
bat cache --build >/dev/null 2>&1
batcat cache --build >/dev/null 2>&1

echo "Installation Complete"
echo

echo "Ensure the below packages are installed for full functionality"
echo ${dependencies[@]}
echo "Installs using brew"
echo ${brew_installs[@]}

exec zsh
