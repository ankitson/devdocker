#!/bin/bash

set -x
set -e

export DEBIAN_FRONTEND=noninteractive

sudo apt update && sudo apt upgrade -y

sudo apt install -y -q \
  build-essential      \
  zsh                  \
  neovim               \
  fzf                  \
  ripgrep              \
  jq 		       \
  git 		       \
  git-man              \
  tmux                 \
  curl                 \
  wget                 \
  openssh-server       \
  unzip                \
  python3              \
  python3-pip          \
  python3-venv       

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y -q nodejs

#ohmyzsh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" --unattended
