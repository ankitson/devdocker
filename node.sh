#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# node/npm/pnpm/typescript
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=21
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt install -y -q nodejs



#SHELL=/bin/bash pnpm setup

#curl -sL https://deb.nodesource.com/setup_current.x | sudo -E bash -
#sudo apt install -y -q nodejs

#wget -qO- https://get.pnpm.io/install.sh | sh -
#curl -f https://get.pnpm.io/v6.16.js | sudo node - add --global pnpm

## mkdir ~/.npm-global
## npm config set prefix '~/.npm-global'

#npm install -g pnpm


#sudo node - add --global pnpm
#SHELL=/bin/bash pnpm setup
#source ~/.bashrc
#pnpm add typescript --global
