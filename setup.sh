#!/bin/bash

rm -rf $HOME/.dot $HOME/.dotfiles $HOME/.oh-my-zsh $HOME/.tmux

echo "Setting up environment"

dot() {
  GIT_DIR=$HOME/.dot/.git/ GIT_WORK_TREE=$HOME /usr/bin/git "$@"
}

echo "Cloning dotfiles to ${HOME}/.dot"
git clone --no-checkout https://github.com/windweaver828/dotfiles.git $HOME/.dot || {
  echo "Cloning failed..."
  exit 1
}
dot reset --hard
dot checkout -f main
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
