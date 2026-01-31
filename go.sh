#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# go
sudo wget https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.25.6.linux-amd64.tar.gz

# fzf (Ubuntu 22.04 apt has 0.29, latest is 0.57+)
GOBIN=/usr/local/bin /usr/local/go/bin/go install github.com/junegunn/fzf@latest
