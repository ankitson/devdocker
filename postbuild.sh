#!/bin/bash

# Run on first interactive login
sudo unminimize

vim +'PlugInstall --sync' +qa

# commit the image after to save changes. do NOT push the commited image
