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
echo "[1/2] Initializing chezmoi (agent mode)..."
chezmoi init --apply

# 2. Re-apply chezmoi
echo "[2/2] Re-applying chezmoi..."
chezmoi apply --force

# Mark first-run as complete (suppresses login reminder)
touch "$HOME/.first-run-done"

echo ""
echo "=== Agent setup complete ==="
echo "  - chezmoi: is_agent=true, personal=true"
echo "  - SSH keys: deployed from op://Agents/agent-ssh"
echo "  - git identity: Devbox Agent <agent@ankitson.com>"
