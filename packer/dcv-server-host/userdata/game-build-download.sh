#! /bin/bash

set -e
set -x

function log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/log/userdata.log
}

log "============================================"
log "Game build download start"
log "============================================"

log "Creating game build directory"

if ! sudo mkdir -p /opt/dcv/game-build; then
    log "Failed to create game build directory"
    exit 1
fi

log "Setting permissions"

if ! sudo chown -R ubuntu:docker /opt/dcv/game-build; then
    log "Failed to set permissions"
    exit 1
fi

if ! sudo chmod -R 755 /opt/dcv/game-build; then
    log "Failed to set permissions"
    exit 1
fi

log "Delete existing game build folder contents"

if ! sudo rm -rf /opt/dcv/game-build/*; then
    log "Failed to delete existing game build folder contents"
    exit 1
fi

log "Downloading game build"

aws s3 cp s3://${UNITY_BUILD_BUCKET}/${UNITY_BUILD_PATH}/unity-build-${UNITY_BUILD_VERSION}.zip /opt/dcv/game-build/   

log "Unzipping game build"

if ! sudo unzip -o /opt/dcv/game-build/unity-build-${UNITY_BUILD_VERSION}.zip -d /opt/dcv/game-build/; then
    log "Failed to unzip game build"
    exit 1
fi

log "Setting permissions"

if ! sudo chown -R ubuntu:docker /opt/dcv/game-build; then
    log "Failed to set permissions"
    exit 1
fi

if ! sudo chmod -R 755 /opt/dcv/game-build; then
    log "Failed to set permissions"
    exit 1
fi

log "Game build download complete"
