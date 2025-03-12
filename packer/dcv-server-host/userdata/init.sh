#!/bin/bash
set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Init START"
log "============================================"

log "Updating packages"
if ! apt update -y; then
    log "Failed to update packages"
    exit 1
fi

log "Upgrading packages"
if ! apt upgrade -y; then
    log "Failed to upgrade packages"
    exit 1
fi

# TODO: Move unzip installation here.
log "Installing unzip"
if ! apt install -y unzip; then
    log "Failed to install unzip"
    exit 1
fi

# # TODO: Add x11-utils installation maybe here, maybe later after xvfb.
# log "Installing x11-utils"
# if ! apt install -y x11-utils; then
#     log "Failed to install x11-utils"
#     exit 1
# fi
