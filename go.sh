#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# go
sudo wget https://go.dev/dl/go1.25.6.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.25.6.linux-amd64.tar.gz
