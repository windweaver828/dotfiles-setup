#!/bin/bash

if [[ ! -e $HOME/.dot ]]; then
    git clone https://windweaver828@bitbucket.org/windweaver828/dotfiles.git $HOME/.dot
    #dot='/usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME'
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME restore .
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME submodule update --init --recursive --force
    /usr/bin/git --git-dir=$HOME/.dot/.git/ --work-tree=$HOME config --local status.showUntrackedFiles no
fi

# Install oh-my-zsh and custom files
rm -rf $HOME/.oh-my-zsh/custom
ln -s $HOME/.dotfiles/oh-my-zsh-custom $HOME/.oh-my-zsh/custom
