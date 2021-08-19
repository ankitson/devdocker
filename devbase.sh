#!/bin/bash

set -x
set -e

sudo apt update && sudo apt upgrade -y

#command line tools
sudo apt install -y -q \
  build-essential      \
  zsh                  \
  neovim               \
  fzf                  \
  tree                 \
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
  iproute2             \
  iputils-ping         \
  traceroute           \
  dnsutils             \
  unzip                \
  rsync                \

#language toolchains
# python
sudo apt install -y -q \
  python3              \
  python3-pip          \
  python3-venv

# nodejs
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt install -y -q nodejs

# rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# postgres and sqlite
sudo apt install -y -q \
  postgresql-client-12 \
  libpq-dev \
  sqlite3 sqlite3-doc \

#tools that depend on language toolchain
$HOME/.cargo/bin/cargo install fselect
