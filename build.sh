#!/bin/bash

sudo DOCKER_BUILDKIT=1 docker build --no-cache --rm -t ankit/devbox:0.6-cuda-test . 2>&1 | tee build.log
