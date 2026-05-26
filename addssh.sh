#!/bin/sh
set -e

username=$1
sshdir="/home/$username/.ssh"
mkdir -p "$sshdir"

# Copy whichever key types are provided in ssh-keys/
cp ./ssh-keys/dev.pem "$sshdir/id_ed25519"
cp ./ssh-keys/dev.pub "$sshdir/id_ed25519.pub"
chmod 600 "$sshdir/id_ed25519"
chmod 644 "$sshdir/id_ed25519.pub"

# Build authorized_keys from all public keys
cat "$sshdir"/*.pub > "$sshdir/authorized_keys" 2>/dev/null || true
chmod 644 "$sshdir/authorized_keys"

chown -R 1000:1000 "$sshdir"
chmod 700 "$sshdir"

# Install persistent SSH host keys (so the fingerprint survives rebuilds)
for keytype in ed25519 rsa ecdsa; do
  keyfile="./ssh-keys/ssh_host_${keytype}_key"
  if [ -f "$keyfile" ]; then
    cp "$keyfile" "/etc/ssh/ssh_host_${keytype}_key"
    cp "${keyfile}.pub" "/etc/ssh/ssh_host_${keytype}_key.pub"
    chmod 600 "/etc/ssh/ssh_host_${keytype}_key"
    chmod 644 "/etc/ssh/ssh_host_${keytype}_key.pub"
  fi
done
