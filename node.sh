#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# node via nodesource
sudo apt-get install -y ca-certificates curl gnupg
curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
NODE_MAJOR=25
echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list
sudo apt-get update
sudo apt install -y -q nodejs

sudo npm install -g pnpm
sudo npm install -g bun
sudo npm install -g typescript

# AI coding assistants
sudo npm install -g @openai/codex
sudo npm install -g @google/gemini-cli
sudo npm install -g @earendil-works/pi-coding-agent   # pi coding agent CLI
sudo npm install -g pi-acp                            # ACP adapter for pi (spawns `pi --mode rpc`)
sudo npm install -g opencode-ai                       # opencode coding agent CLI (native acpx harness)
