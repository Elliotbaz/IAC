#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Installing docker START"
log "============================================"

[ -f /etc/os-release ] && . /etc/os-release

log "Installing docker"
curl --silent https://get.docker.com | sh  && sudo systemctl --now enable docker

log "Installing nVidia container environment "
distribution=$(. /etc/os-release;echo ubuntu$VERSION_ID) \
    && curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add - \
    && curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list
sudo apt-get update
sudo apt-get install -y nvidia-docker2

sudo usermod -aG docker ubuntu
newgrp docker

sudo systemctl restart docker

log "Finished nVidia container environment "
sleep 1

log "Finished installing docker and nVidia container environment"
