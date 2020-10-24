1. ./build.sh to build the image

2. create an external volume: 

docker volume create devbox_home

3. run container with volume "devbox_home" mounted at /home/ankit

4. mount ssh keys into container and install
    sudo docker run -it --volumes-from <container_id> --mount type=bind,src=/home/ankit/dockers/devenv/ssh-keys,dst=/home/ankit/ssh-keys/ alpine
    
    cd /home/ankit/
    chmod +x addssh.sh
    ./addssh.sh ankit 

5. ssh into the container with:
  ssh -P 2201 ankit@localhost

6. track the dotfiles repo instead of a static copy: (hack because ssh keys should not be in docker image)
   cd /home/ankit/
   rm -rf /home/ankit/dotfiles
   git clone git@github.com:ankitson/dotfiles.git

