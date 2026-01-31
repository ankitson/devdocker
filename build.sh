#!/bin/bash

sudo DOCKER_BUILDKIT=1 docker build --rm -t ankit/devbox:1.0 . 2>&1 | tee logs/build.log
