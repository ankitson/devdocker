#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# python
sudo apt install -y -q \
  python3              \
  python3-pip          \

# numpy/scipy stack
export PATH=$HOME/.local/bin/:$PATH
pip3 install         \
  numpy              \
  scipy              \
  pandas             \
  matplotlib         \
  sympy              \
  nose               \
  jax[cpu]           \

# segfaults if installed with others
pip3 install         \
  ipython            \
