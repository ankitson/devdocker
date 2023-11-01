#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# Clang
sudo apt install -y -q   \
  clang                  \
  clang-format           \
  clang-tidy             \
  clang-tools            \
  clangd                 \
  libc++-dev             \
  libc++1                \
  libc++abi-dev          \
  libc++abi1             \
  libclang-dev           \
  libclang1              \
  liblldb-dev            \
  libllvm-ocaml-dev      \
  libomp-dev             \
  libomp5                \
  lld                    \
  lldb                   \
  llvm-dev               \
  llvm-runtime           \
  llvm                   \
  python3-clang          

# cmake
sudo apt install -y -q   \
  cmake                  \
  cmake-doc              \
  ninja-build            \
  cmake-format           