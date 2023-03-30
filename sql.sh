#!/bin/bash
set -x
set -e
sudo apt update && sudo apt upgrade -y

# postgres and sqlite
sudo apt install -y -q \
  postgresql-client-14 \
  libpq-dev \
  sqlite3 sqlite3-doc \
