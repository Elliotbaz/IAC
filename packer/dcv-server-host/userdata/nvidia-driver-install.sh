#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Installing nVidia driver on the host START"
log "============================================"

sleep 1

log "Installing nVidia driver for ubuntu"
sudo apt-get update -y
sudo apt-get install -y gcc make linux-headers-$(uname -r)

log "Installing awscli"
sudo apt install -y awscli

log "Downloading nVidia driver from S3"
aws s3 cp --no-sign-request --recursive s3://ec2-linux-nvidia-drivers/${GRID_DRIVER_VERSION}/ .

log "Moving nVidia driver to /tmp"
mv ./NVIDIA-Linux-x86_64*.run /tmp/NVIDIA-installer.run
sudo bash /tmp/NVIDIA-installer.run --accept-license --no-questions --no-backup --ui=none
mv /tmp/NVIDIA-installer.run /opt/dcv/NVIDIA-installer.run    # we need it later for the container

log "Finished nVidia driver installation"
sleep 0.75
