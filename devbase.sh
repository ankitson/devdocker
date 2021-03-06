#!/bin/bash

set -x
set -e

sudo apt update && sudo apt upgrade -y

sudo apt install -y -q \
  build-essential      \
  zsh                  \
  neovim               \
  fzf                  \
  ripgrep              \
  fd-find              \
  htop                 \
  jq                   \
  git                  \
  git-man              \
  tmux                 \
  curl                 \
  wget                 \
  openssh-server       \
  net-tools            \
  unzip                \
  python3              \
  python3-pip          \
  python3-venv

curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y -q nodejs
