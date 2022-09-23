FROM ubuntu:21.10

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp/build
COPY base.sh /tmp/build/
COPY devbase.sh /tmp/build/
COPY python.sh /tmp/build/
COPY rust.sh /tmp/build/
COPY sql.sh /tmp/build/
COPY go.sh /tmp/build/
COPY node.sh /tmp/build/

RUN apt update 
RUN bash -c 'yes | unminimize'
RUN apt install -y language-pack-en
ENV LANGUAGE=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
RUN bash -c 'locale-gen en_US.UTF-8 && dpkg-reconfigure locales'
ENV TZ=America/Vancouver
RUN apt install -y tzdata

RUN bash base.sh

USER ankit
RUN bash devbase.sh
RUN bash python.sh
RUN bash rust.sh
RUN bash sql.sh
RUN bash go.sh
RUN bash node.sh
WORKDIR /

RUN sudo rm -rf /tmp/build

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
RUN bash /home/ankit/dotfiles/link.sh

#VOLUME ["/home/ankit/"]


# Run an ssh server.
USER root
RUN mkdir /var/run/sshd
ENTRYPOINT ["/usr/sbin/sshd",  "-D"]
EXPOSE 22
