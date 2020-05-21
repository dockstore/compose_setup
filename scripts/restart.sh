#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Restarts stack by running commands from /home/ubuntu/compose_setup

cd /home/ubuntu/compose_setup
docker-compose down
nohup docker-compose up --force-recreate --remove-orphans >/dev/null 2>&1 &
