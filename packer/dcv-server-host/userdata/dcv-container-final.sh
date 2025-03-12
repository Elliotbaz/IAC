#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Building DCV container build script START"
log "============================================"

cd /opt/dcv

# log "Creating DCV directories"
# sudo mkdir -p /run/dcv
# sudo touch /run/dcv/usersession-1.xauth
# sudo touch /run/dcv/usersession-2.xauth

# log "Setting permissions for DCV directories"
# sudo chown 1000:1000 /run/dcv/usersession-*.xauth
# sudo chmod 600 /run/dcv/usersession-*.xauth

log "Building DCV container"
sudo docker build -t dcv-server --build-arg PORT=8443 -f Dockerfile.dcv .

log "Finished building DCV container."