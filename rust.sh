#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# rust - stable and nightly, default to nightly
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
export PATH=$HOME/.cargo/bin:$PATH
rustup default nightly

# rust wasm
curl https://rustwasm.github.io/wasm-pack/installer/init.sh -sSf | sh 

#$HOME/.cargo/bin/cargo install fselect
$HOME/.cargo/bin/cargo install flamegraph
$HOME/.cargo/bin/cargo install cargo-generate
$HOME/.cargo/bin/cargo install exa
