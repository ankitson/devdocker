#FROM ubuntu:21.10
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04 AS devbase

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp/build
COPY base.sh /tmp/build/
COPY devbase.sh /tmp/build/
COPY python.sh /tmp/build/
COPY cpp.sh /tmp/build/
COPY node.sh /tmp/build/
COPY install_pnpm.sh /tmp/build/
COPY rust.sh /tmp/build/
COPY sql.sh /tmp/build/
COPY go.sh /tmp/build/

# the below command and mounts are so that APT downloads packages to the host and doesn't need to redownload for each build
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt update 
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked bash -c 'yes | unminimize'
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt install -y language-pack-en
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked bash -c 'locale-gen en_US.UTF-8 && dpkg-reconfigure locales'
ENV TZ=America/Vancouver
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt install -y tzdata

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked bash base.sh

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked --mount=type=cache,target=/var/lib/apt,sharing=locked apt install -y -q curl

FROM devbase AS devbase_langtoolchains
USER ankit
RUN bash devbase.sh
RUN bash python.sh
RUN bash cpp.sh
RUN bash node.sh
RUN wget -qO- https://get.pnpm.io/install.sh | ENV="$HOME/.bashrc" SHELL="$(which bash)" bash -
ENV PATH="/home/ankit/.local/share/pnpm:${PATH}"
ENV PNPM_HOME="/home/ankit/.local/share/pnpm"
RUN /home/ankit/.local/share/pnpm/pnpm add typescript --global
RUN bash rust.sh
RUN bash sql.sh
RUN bash go.sh

WORKDIR /

RUN sudo rm -rf /tmp/build

FROM devbase_langtoolchains AS devbox

WORKDIR /home/ankit
COPY addssh.sh /home/ankit/
COPY postbuild.sh /home/ankit/
RUN sudo chown ankit:users postbuild.sh
RUN sudo chmod +x /home/ankit/postbuild.sh

COPY dotfiles/ /home/ankit/dotfiles
RUN sudo chown -R ankit:users /home/ankit/dotfiles

COPY bin/ /home/ankit/bin
RUN sudo chown -R ankit:users /home/ankit/bin

WORKDIR /home/ankit/dotfiles/
RUN rm /home/ankit/.bashrc
RUN bash /home/ankit/dotfiles/link.sh

#VOLUME ["/home/ankit/"]

# Run an ssh server.
USER root
RUN mkdir /var/run/sshd

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
