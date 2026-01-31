#!/bin/bash
set -x
set -e

# install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# Use a temp cache dir during build — the /projects mount doesn't exist yet,
# so the system uv.toml cache-dir would write to a shadowed image layer.
export UV_CACHE_DIR=/tmp/uv-cache-build
export UV_HTTP_TIMEOUT=300

# install python via uv (replaces pyenv)
uv python install 3.14 3.12

# Lightweight scratch venv for interactive use (ipython, quick scripts).
# NOT a cache mechanism — the host-shared uv cache at /projects/.uv-cache
# handles cross-project package reuse.
#
# Heavy CUDA packages (torch, jax) are installed per-project via `uv add`
# and cached on the host mount. See docs/uv-caching.md.
export VIRTUAL_ENV=/home/ankit/python-base
uv venv ${VIRTUAL_ENV} --python 3.12

uv pip install \
  python-dotenv      \
  numpy              \
  scipy              \
  pandas             \
  matplotlib         \
  sympy              \
  ipython            \

# CLI tools
uv tool install pre-commit
uv tool install ruff

# Clean up the throwaway build cache
rm -rf /tmp/uv-cache-build
