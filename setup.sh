#!/bin/bash

# Delete all the dotfiles
cd $HOME
rm -rf .dot .dotfiles .zsh_history .zshrc .zcompdump-localhost-5.9 .zcompdump-localhost-5.9.zwc .tmux .tmux.conf .oh-my-zsh .pylintrc .gitignore .git-credentials .gitconfig .gitmodules .config/lsd .config/nvim .local/share/nvim

if [[ ! -e $HOME/.dot ]]; then
    git clone https://windweaver828@bitbucket.org/windweaver828/dotfiles.git $HOME/.dot
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME restore .
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME submodule update --init --recursive --force
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME config --local status.showUntrackedFiles no
fi

# Install oh-my-zsh and custom files
rm -rf $HOME/.oh-my-zsh/custom
ln -s $HOME/.dotfiles/oh-my-zsh-custom $HOME/.oh-my-zsh/custom
