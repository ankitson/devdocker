#!/bin/bash
set -x
set -e

sudo apt update && sudo apt upgrade -y

#NOTE: no whitespace after slashes in the following lines

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

wget -qO - 'https://proget.makedeb.org/debian-feeds/prebuilt-mpr.pub' | gpg --dearmor | sudo tee /usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg 1> /dev/null
echo "deb [arch=all,$(dpkg --print-architecture) signed-by=/usr/share/keyrings/prebuilt-mpr-archive-keyring.gpg] https://proget.makedeb.org prebuilt-mpr $(lsb_release -cs)" | sudo tee /etc/apt/sources.list.d/prebuilt-mpr.list
sudo apt update
sudo apt install -y -q just

# ADD CLOUDFLARE TUNNEL
curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg | sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/cloudflared.list
sudo apt update
sudo apt install -y -q cloudflared

# add docker-ce-cli, for docker-in-docker. the host docker socket must be mounted in the container
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt update
sudo apt install -y -q docker-ce-cli
