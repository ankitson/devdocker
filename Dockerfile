FROM nvidia/cuda:13.1.2-cudnn-devel-ubuntu24.04 AS devbase

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp/build

# apt setup and system packages (no COPY dependencies — cached until base image changes)
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN apt update
RUN bash -c 'yes | unminimize'
RUN apt install -y language-pack-en
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN bash -c 'locale-gen en_US.UTF-8 && dpkg-reconfigure locales'
ENV TZ=America/Vancouver
RUN apt install -y tzdata
RUN apt install -y -q curl

# base.sh: creates user, installs core apt packages
COPY base.sh /tmp/build/
RUN bash base.sh

FROM devbase AS devbase_langtoolchains
WORKDIR /tmp/build

# --- system-wide installs (run as root) ---

COPY devbase.sh /tmp/build/
RUN bash devbase.sh

COPY cpp.sh /tmp/build/
RUN bash cpp.sh

COPY node.sh /tmp/build/
RUN bash node.sh

COPY sql.sh /tmp/build/
RUN bash sql.sh

COPY go.sh /tmp/build/
RUN bash go.sh

# System-wide uv config (PyTorch CUDA index, host-shared cache at /projects/.uv-cache)
COPY uv.toml /etc/uv/uv.toml

# --- user home dir installs ---
USER ankit

COPY python-uv.sh /tmp/build/
RUN bash python-uv.sh

COPY rust.sh /tmp/build/
RUN bash rust.sh

# Claude Code (native binary, installs to ~/.local/bin)
RUN curl -fsSL https://claude.ai/install.sh | bash

WORKDIR /

RUN sudo rm -rf /tmp/build

FROM devbase_langtoolchains AS devbox

WORKDIR /home/ankit

# SSH keys
COPY addssh.sh /home/ankit
COPY ssh-keys/ /home/ankit/ssh-keys
RUN sudo bash addssh.sh ankit && sudo rm -rf /home/ankit/addssh.sh /home/ankit/ssh-keys/

# Dotfiles via chezmoi
# Install chezmoi, clone dotfiles via SSH (using host's SSH agent via --mount=type=ssh),
# then two-pass apply: first creates .bashrc with PATH, second (via interactive
# bash) gets full PATH so lookPath succeeds for eza, cargo, uv, etc.
RUN sudo sh -c "$(curl -fsLS get.chezmoi.io)" -- -b /usr/local/bin
RUN mkdir -p ~/.ssh && ssh-keyscan github.com >> ~/.ssh/known_hosts
RUN --mount=type=ssh git lfs install && git clone git@github.com:ankitson/dotfiles.git ~/.local/share/chezmoi
COPY --chown=ankit:users chezmoi.toml /home/ankit/.config/chezmoi/chezmoi.toml
RUN chezmoi apply --force && bash -ic 'chezmoi apply --force'

# Wezterm: symlink to /usr/local/bin so SSHMUX can find the binaries
# (user-local paths like ~/.local/bin/vendor aren't on the SSHMUX lookup path)
RUN sudo ln -sf /home/ankit/.local/bin/vendor/wezterm /usr/local/bin/wezterm && \
    sudo ln -sf /home/ankit/.local/bin/vendor/wezterm-mux-server /usr/local/bin/wezterm-mux-server && \
    sudo ln -sf /home/ankit/.local/bin/vendor/strip-ansi-escapes /usr/local/bin/strip-ansi-escapes

# First-run setup scripts
COPY --chown=ankit:users first-run.sh /home/ankit/first-run.sh
COPY --chown=ankit:users agent-first-run.sh /home/ankit/agent-first-run.sh

# Projects mount point + uv README
RUN sudo mkdir -p /projects && sudo chown ankit:users /projects
COPY --chown=ankit:users docs/uv-README.md /home/ankit/uv-README.md

# Run an ssh server.
USER root
RUN mkdir /var/run/sshd

# Login message: remind to run first-run.sh (or agent-first-run.sh) if not yet done
RUN printf '#!/bin/bash\nif [ ! -f "$HOME/.first-run-done" ] && [ -f "$HOME/first-run.sh" ]; then\n  echo ""\n  if [ -n "${OP_SERVICE_ACCOUNT_TOKEN:-}" ]; then\n    echo "  Agent mode detected. Run ~/agent-first-run.sh"\n  else\n    echo "  *** First time? Run ~/first-run.sh to set up 1Password + personal dotfiles ***"\n  fi\n  echo ""\nfi\n' > /etc/profile.d/first-run-notice.sh

# Harden sshd
RUN sed -i 's/#\?PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed -i 's/#\?PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    grep -q "^AllowUsers ankit" /etc/ssh/sshd_config || echo "AllowUsers ankit" >> /etc/ssh/sshd_config && \
    sed -i 's/#\?X11Forwarding .*/X11Forwarding no/' /etc/ssh/sshd_config && \
    (grep -q "^ClientAliveInterval" /etc/ssh/sshd_config || echo "ClientAliveInterval 300" >> /etc/ssh/sshd_config) && \
    (grep -q "^ClientAliveCountMax" /etc/ssh/sshd_config || echo "ClientAliveCountMax 2" >> /etc/ssh/sshd_config) && \
    (grep -q "^UseDNS" /etc/ssh/sshd_config || echo "UseDNS no" >> /etc/ssh/sshd_config)

ENTRYPOINT ["/usr/sbin/sshd",  "-D"]
EXPOSE 22
