#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# python
sudo apt install -y -q \
  python3              \
  python3-pip          \

# dependencies to build python versions, used by pyenv
sudo apt install -y -q build-essential libssl-dev zlib1g-dev \
libbz2-dev libreadline-dev libsqlite3-dev curl \
libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev

# pyenv
curl https://pyenv.run | bash

export PATH=$HOME/.local/bin/:$PATH

# utils
pip3 install python-dotenv

# numpy/scipy stack
pip3 install         \
  numpy              \
  scipy              \
  pandas             \
  matplotlib         \
  sympy              \
  nose               \
  jax[cpu]           \

#LLM
pip3 install         \
  langchain          \
  openai             \
  huggingface-hub    \

# segfaults if installed with others
pip3 install         \
  ipython            \
