#!/bin/bash
set -x
set -e

# Playwright browser automation — Chromium + WebKit
#
# Installs playwright globally (npm) so the version is pinned and matches the
# browser binaries. Uses PLAYWRIGHT_BROWSERS_PATH to put browsers in a shared
# location accessible to all users.

BROWSERS_PATH=/opt/playwright-browsers

# Install playwright as a global npm package
sudo npm install -g playwright

# Set env vars globally:
#   - PLAYWRIGHT_BROWSERS_PATH: shared browser location
#   - NODE_PATH: so require('playwright') works without local install
#   - /etc/environment: read by PAM/sshd for SSH sessions
#   - /etc/profile.d/: read by login shells
NODE_MODULES=$(npm root -g)
sudo tee /etc/profile.d/playwright.sh > /dev/null <<EOF
export PLAYWRIGHT_BROWSERS_PATH=$BROWSERS_PATH
export NODE_PATH="${NODE_MODULES}\${NODE_PATH:+:\$NODE_PATH}"
EOF
cat <<ENVEOF | sudo tee -a /etc/environment > /dev/null
PLAYWRIGHT_BROWSERS_PATH=$BROWSERS_PATH
NODE_PATH=$NODE_MODULES
ENVEOF

# Install system deps + browser binaries into shared location
export PLAYWRIGHT_BROWSERS_PATH="$BROWSERS_PATH"
sudo mkdir -p "$BROWSERS_PATH"
sudo PLAYWRIGHT_BROWSERS_PATH="$BROWSERS_PATH" npx playwright install-deps chromium webkit
sudo PLAYWRIGHT_BROWSERS_PATH="$BROWSERS_PATH" npx playwright install chromium webkit
sudo chown -R ankit:users "$BROWSERS_PATH"
sudo chmod -R u+rwX,go+rX "$BROWSERS_PATH"
