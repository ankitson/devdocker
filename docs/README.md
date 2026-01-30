This is a docker image with a lot of dev tools and language toolchains pre-installed.

1. Build the docker image

`(host)> sudo ./build.sh`

2. Create an external volume:

`(host)> sudo docker volume create devbox_home`

3. Run container

`(host)> sudo docker-compose up`

4. Mount ssh keys into container and install

   ```
   (host)> sudo docker run -it --volumes-from <container_id> --mount type=bind,src=`pwd`/ssh-keys,dst=/home/ankit/ssh-keys/ alpine

   (docker)# cd /home/ankit/
   (docker)# chmod +x addssh.sh
   (docker)# ./addssh.sh ankit
   ```

5. ssh into the container:

`ssh -P 2201 ankit@localhost`

6. track the dotfiles repo instead of a static copy: (ssh keys should not be in docker image)

   ```
   (docker)# cd /home/ankit/
   (docker)# rm -rf /home/ankit/dotfiles
   (docker)# git clone git@github.com:ankitson/dotfiles.git
   ```

7. run `postbuild.sh` to unminimize:

   ```
   (docker)# cd /home/ankit
   (docker)# ./postbuild.sh
   ```

8. commit the unminimized version:

   ```
   (host)> sudo docker commit <container_id> ankit/devbox:unminim
   ```

9. now use the commited image. remember to commit when you make changes outside of the mounted volumes you want to persist across container rebuild

   thanks to AuFS, new commits/images are only layers on top of previous images so disk use is low.

** Any images created after copying the ssh keys in (eg "unminim") should NOT be published **
