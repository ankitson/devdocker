#!/usr/bin/env bash
# agent-first-run.sh — non-interactive setup for automated agents.
# Requires OP_SERVICE_ACCOUNT_TOKEN in environment.
# chezmoi detects the token and sets is_agent=true, personal=true automatically.
set -euo pipefail

if [ -z "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then
  echo "ERROR: OP_SERVICE_ACCOUNT_TOKEN not set" >&2
  exit 1
fi

echo "=== Agent setup ==="

# 1. chezmoi init detects OP_SERVICE_ACCOUNT_TOKEN -> is_agent=true, personal=true
echo "[1/3] Initializing chezmoi (agent mode)..."
chezmoi init --apply

# 2. Switch dotfiles remote to SSH (agent now has SSH keys deployed)
echo "[2/3] Switching dotfiles remote to SSH..."
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:ankitson/dotfiles.git

# 3. Re-apply with SSH remote configured
echo "[3/3] Re-applying chezmoi..."
chezmoi apply --force

# Mark first-run as complete (suppresses login reminder)
touch "$HOME/.first-run-done"

echo ""
echo "=== Agent setup complete ==="
echo "  - chezmoi: is_agent=true, personal=true"
echo "  - SSH keys: deployed from op://Agents/agent-ssh"
echo "  - dotfiles remote: git@github.com:ankitson/dotfiles.git (SSH)"
echo "  - git identity: Devbox Agent <agent@ankitson.com>"
