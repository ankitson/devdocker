#!/bin/bash
set -x
set -e

sudo apt update && sudo apt upgrade -y

#NOTE: no whitespace after slashes in the following lines

# build dependencies
sudo apt install -y -q       \
  pkg-config                 \
  build-essential            \
  libssl-dev                 \
  openssh-server             \
  software-properties-common \
  curl                       \
  wget                       \

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
  tree                 \
  jq                   \
  tmux                 \
  curl                 \
  wget                 \
  unzip                \
  rsync                \

# git (newer version supports zdiff3)
sudo apt install -y -q 
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt update
sudo apt install -y -q git git-man

# git-lfs (latest from GitHub, not stale apt version)
GIT_LFS_VERSION="$(curl -fsSL https://api.github.com/repos/git-lfs/git-lfs/releases/latest | jq -r '.tag_name' | sed 's/^v//')" && \
  curl -fsSL "https://github.com/git-lfs/git-lfs/releases/download/v${GIT_LFS_VERSION}/git-lfs-linux-amd64-v${GIT_LFS_VERSION}.tar.gz" \
  | sudo tar xz -C /usr/local/bin/ --strip-components=1 --wildcards '*/git-lfs' && \
  git lfs install

# neovim (Ubuntu 22.04 has 0.6, latest is 0.10+)
curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz" \
  | sudo tar xz -C /opt/ && sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim

# fzf, ripgrep, fd installed via go/cargo in go.sh and rust.sh respectively

curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | sudo bash -s -- --to /usr/local/bin

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

# add terraform (SHA256 verified, GPG signature check skipped — HashiCorp key import
# fails in minimal Docker builds without a pre-seeded keyring)
wget https://releases.hashicorp.com/terraform/1.14.4/terraform_1.14.4_linux_amd64.zip && \
  wget https://releases.hashicorp.com/terraform/1.14.4/terraform_1.14.4_SHA256SUMS && \
  grep terraform_1.14.4_linux_amd64.zip terraform_1.14.4_SHA256SUMS | sha256sum -c && \
  sudo unzip terraform_1.14.4_linux_amd64.zip -d /usr/local/bin/ && \
  rm -f terraform_1.14.4_linux_amd64.zip terraform_1.14.4_SHA256SUMS

# add 1password
ARCH="amd64"; \
  OP_VERSION="v$(curl https://app-updates.agilebits.com/check/1/0/CLI2/en/2.0.0/N -s | grep -Eo '[0-9]+\.[0-9]+\.[0-9]+')"; \
  curl -sSfo op.zip \
  https://cache.agilebits.com/dist/1P/op2/pkg/"$OP_VERSION"/op_linux_amd64_"$OP_VERSION".zip \
  && sudo unzip -od /usr/local/bin/ op.zip \
  && rm op.zip

# add gitea tea cli
curl -fsSL https://dl.gitea.com/tea/0.11.1/tea-0.11.1-linux-amd64 -o tea && \
  sudo install -m 755 tea /usr/local/bin/tea && \
  rm tea

# pandoc + PDF dependencies (LaTeX engine, pango, fonts, SVG support)
sudo apt install -y -q \
  pandoc                \
  libpango-1.0-0       \
  libpangocairo-1.0-0  \
  libpangoft2-1.0-0    \
  librsvg2-bin         \
  texlive-latex-base   \
  texlive-latex-recommended \
  texlive-latex-extra  \
  texlive-fonts-recommended \
  texlive-xetex        \
  lmodern              \

# add duckdb
curl -fsSL https://install.duckdb.org/v1.4.4/duckdb_cli-linux-amd64.gz | gunzip > duckdb && \
  sudo install -m 755 duckdb /usr/local/bin/duckdb && \
  rm duckdb
