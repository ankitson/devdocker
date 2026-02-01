#!/usr/bin/env bash
# first-run.sh — run once after first SSH into a fresh devbox container.
# Sets up 1Password auth, switches chezmoi to personal mode, and configures
# the dotfiles remote for SSH push access.
set -euo pipefail

echo "=== Devbox first-run setup ==="
echo ""

# 1. Sign into 1Password
echo "[1/4] Signing into 1Password..."
eval "$(op signin)"

# 2. Switch chezmoi config to personal=true and re-init
echo "[2/4] Re-initializing chezmoi (personal=true)..."
chezmoi init --apply

# 3. Switch dotfiles remote from HTTPS to SSH (for push access)
echo "[3/4] Switching dotfiles remote to SSH..."
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:ankitson/dotfiles.git

# 4. Re-apply chezmoi with full personal config
echo "[4/4] Applying chezmoi with personal config..."
chezmoi apply --force

# Mark first-run as complete (suppresses login reminder)
touch "$HOME/.first-run-done"

echo ""
echo "=== Done! ==="
echo "  - 1Password: authenticated"
echo "  - chezmoi: personal=true, internal_network=true"
echo "  - dotfiles remote: git@github.com:ankitson/dotfiles.git (SSH)"
echo ""
echo "You can now use 'chezmoi update' to pull dotfile changes,"
echo "or 'chezmoi edit <file>' to make and push changes."
