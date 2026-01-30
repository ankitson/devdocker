#!/bin/bash

# Run on first interactive login
sudo unminimize
sudo mkdir -p /projects && sudo chown ankit:users /projects
git clone https://github.com/ankitson/dotfiles.git /home/ankit/dotfiles
WORKDIR /home/ankit/dotfiles/
RUN bash /home/ankit/dotfiles/link.sh
vim +'PlugInstall --sync' +qa

# commit the image after to save changes. do NOT push the commited image
