#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# build dependencies
sudo apt install -y -q   \
  pkg-config             \
  build-essential        \
  libssl-dev             \
  openssh-server         \
  curl                   \
  wget                   \

# perf
sudo apt install -y -q   \
  linux-tools-common     \
  linux-tools-generic    \
# HACK:
# perf complains about missing linux-tools even on a linux host (same kernel..)
# maybe related to https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1844443?
sudo cp /usr/lib/linux-tools/*/perf /usr/bin/perf

# sys monitoring
sudo apt install -y -q \
  dstat                \
  strace               \
  htop                 \
  net-tools            \
  iproute2             \
  iputils-ping         \
  traceroute           \
  dnsutils             \
  netcat               \
  ngrep                \
  tcpdump              \

#misc cli tools
sudo apt install -y -q \
  zsh                  \
  neovim               \
  fzf                  \
  tree                 \
  ripgrep              \
  fd-find              \
  jq                   \
  git                  \
  git-man              \
  tmux                 \
  curl                 \
  wget                 \
  unzip                \
  rsync                \
