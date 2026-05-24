#!/bin/bash

set -x
set -e

#apt update 
#apt install -y language-pack-en
#export LANGUAGE=en_US.UTF-8
#export LANG=en_US.UTF-8
#export LC_ALL=en_US.UTF-8
#locale-gen en_US.UTF-8 && dpkg-reconfigure locales
#export TZ=America/Vancouver

#apt install -y tzdata
yes | unminimize
# Enable passwordless sudo for users in the sudo group.
apt install -y sudo
sed -ie '/sudo/ s/ALL$/NOPASSWD: ALL/' /etc/sudoers

# Ubuntu 24.04 ships with a default 'ubuntu' user at UID 1000; remove it so we can claim that UID.
userdel -r ubuntu 2>/dev/null || true

useradd ankit -u 1000 -d /home/ankit -s /bin/bash -g users -G sudo --no-create-home
mkdir -p /home/ankit && /bin/chown ankit:users /home/ankit

apt install -y man
