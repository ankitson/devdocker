#!/bin/sh

username=$1 
mkdir -p /home/$username/.ssh/
cp ./ssh-keys/dev.pem /home/$username/.ssh/id_rsa
cp ./ssh-keys/dev.pub /home/$username/.ssh/id_rsa.pub
cp ./ssh-keys/dev.pub /home/$username/.ssh/authorized_keys
chown -R 1000:1000 /home/$username/.ssh/
chmod 700 /home/$username/.ssh
chmod 600 /home/$username/.ssh/id_rsa
chmod 644 /home/$username/.ssh/id_rsa.pub
chmod 644 /home/$username/.ssh/authorized_keys
