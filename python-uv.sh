#!/bin/bash
set -x
set -e

# install uv
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="$HOME/.local/bin:$PATH"

# install python via uv (replaces pyenv)
uv python install 3.14 3.12

# shared base venv — all "global" packages go here
export VIRTUAL_ENV=/home/ankit/python-base
export UV_HTTP_TIMEOUT=300
uv venv ${VIRTUAL_ENV} --python 3.12

# utils
uv pip install python-dotenv

# numpy/scipy stack
uv pip install \
  numpy              \
  scipy              \
  pandas             \
  matplotlib         \
  sympy              \
  nose               \

uv pip install -U "jax[cuda12-local]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
uv pip install torch torchvision --index-url https://download.pytorch.org/whl/cu128

# LLM
uv pip install \
  langchain          \
  openai             \
  huggingface-hub    \

# segfaults if installed with others
uv pip install ipython

# CLI tools
uv tool install pre-commit
uv tool install ruff
