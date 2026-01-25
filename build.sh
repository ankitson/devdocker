#!/bin/bash

sudo DOCKER_BUILDKIT=1 docker build --no-cache --rm -t ankit/devbox:0.9 . 2>&1 | tee build.log
