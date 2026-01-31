#!/bin/sh
set -e

username=$1
sshdir="/home/$username/.ssh"
mkdir -p "$sshdir"

# Copy whichever key types are provided in ssh-keys/
if [ -f ./ssh-keys/id_ed25519 ]; then
  cp ./ssh-keys/dev.pem "$sshdir/id_ed25519"
  cp ./ssh-keys/dev.pub "$sshdir/id_ed25519.pub"
  chmod 600 "$sshdir/id_ed25519"
  chmod 644 "$sshdir/id_ed25519.pub"
fi

if [ -f ./ssh-keys/dev.pem ]; then
  cp ./ssh-keys/id_rsa "$sshdir/id_rsa"
  cp ./ssh-keys/id_rsa.pub "$sshdir/id_rsa.pub"
  chmod 600 "$sshdir/id_rsa"
  chmod 644 "$sshdir/id_rsa.pub"
fi

# Build authorized_keys from all public keys
cat "$sshdir"/*.pub > "$sshdir/authorized_keys" 2>/dev/null || true
chmod 644 "$sshdir/authorized_keys"

chown -R 1000:1000 "$sshdir"
chmod 700 "$sshdir"
