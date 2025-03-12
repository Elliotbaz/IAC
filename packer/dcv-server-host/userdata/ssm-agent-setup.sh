#!/bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Installing SSM agent START"
log "============================================"

sudo apt-get update -y
sudo apt-get install -y awslogs

log "============================================"
log "Installing SSM agent END"
log "============================================"