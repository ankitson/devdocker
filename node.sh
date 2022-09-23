#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# node/npm/pnpm/typescript
curl -sL https://deb.nodesource.com/setup_current.x | sudo -E bash -
sudo apt install -y -q nodejs
curl -f https://get.pnpm.io/v6.16.js | sudo node - add --global pnpm
sudo pnpm add typescript --global
