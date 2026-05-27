#!/usr/bin/env bash
# first-run.sh — run once after first SSH into a fresh devbox container.
# Sets up 1Password auth and switches chezmoi to personal mode.
set -euo pipefail

echo "=== Devbox first-run setup ==="
echo ""

# 1. Sign into 1Password
echo "[1/4] Signing into 1Password..."
eval "$(op signin)"

# 2. Switch chezmoi config to personal=true and re-init
echo "[2/4] Re-initializing chezmoi (personal=true)..."
chezmoi init --apply

# 3. Re-apply chezmoi with full personal config
echo "[3/4] Applying chezmoi with personal config..."
chezmoi apply --force

# 4. Install pi packages declared in ~/.pi/agent/settings.json (e.g. pi-subagents).
#    User-settings packages are not auto-installed on startup, so fetch them now.
echo "[4/4] Installing declared pi packages..."
"$HOME/.local/bin/pi" update --extensions || echo "  warn: pi package install failed; run '~/.local/bin/pi update --extensions' manually"

# Mark first-run as complete (suppresses login reminder)
touch "$HOME/.first-run-done"

echo ""
echo "=== Done! ==="
echo "  - 1Password: authenticated"
echo "  - chezmoi: personal=true, internal_network=true"
echo "  - pi packages: installed from settings.json"
echo ""
echo "You can now use 'chezmoi update' to pull dotfile changes,"
echo "or 'chezmoi edit <file>' to make and push changes."
