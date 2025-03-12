#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Building DCV base image START"
log "============================================"

cd /opt/dcv

# # Install Xvfb
# which Xvfb >/dev/null || sudo apt-get update && sudo apt-get install -y xvfb

# # Create necessary directories for volume mounts
# sudo mkdir -p /run/dcv
# sudo touch /run/dcv/usersession-1.xauth
# sudo touch /run/dcv/usersession-2.xauth
# sudo chown 1000:1000 /run/dcv/usersession-*.xauth
# sudo chmod 600 /run/dcv/usersession-*.xauth

sudo docker build -t dcv-base .

log "Finished building DCV base image."
