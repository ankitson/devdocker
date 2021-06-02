FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive

WORKDIR /tmp/build
COPY base.sh /tmp/build/
COPY devbase.sh /tmp/build/
RUN bash base.sh

USER ankit
RUN bash devbase.sh
WORKDIR /

RUN sudo rm -rf /tmp/build

WORKDIR /home/ankit
COPY addssh.sh /home/ankit/
COPY postbuild.sh /home/ankit/
RUN sudo chown ankit:users postbuild.sh
RUN sudo chmod +x /home/ankit/postbuild.sh

COPY dotfiles/ /home/ankit/dotfiles
RUN sudo chown -R ankit:users ~/dotfiles

WORKDIR /home/ankit/dotfiles/
RUN bash /home/ankit/dotfiles/link.sh

#VOLUME ["/home/ankit/"]


# Run an ssh server.
USER root
RUN mkdir /var/run/sshd
ENTRYPOINT ["/usr/sbin/sshd",  "-D"]
EXPOSE 22
