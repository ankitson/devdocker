#!/bin/bash
set -euo pipefail

# Ensure SSH agent is available for BuildKit SSH mount
if [ -z "${SSH_AUTH_SOCK:-}" ] || [ ! -S "$SSH_AUTH_SOCK" ]; then
  echo "ERROR: SSH agent not available (SSH_AUTH_SOCK not set or socket missing)" >&2
  echo "Start an agent and add your key:" >&2
  echo "  eval \"\$(ssh-agent -s)\"" >&2
  echo "  ssh-add ~/.ssh/id_ed25519" >&2
  exit 1
fi

sudo SSH_AUTH_SOCK="$SSH_AUTH_SOCK" DOCKER_BUILDKIT=1 docker build --ssh default --rm -t ankit/devbox:1.4 . 2>&1 | tee logs/build.log

#TODO also tag ankit/devbox:latest
