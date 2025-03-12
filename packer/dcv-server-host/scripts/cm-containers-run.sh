#!/bin/bash

function log() {
    echo $1
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/userdata.log
}

while [[ "$#" -gt 0 ]]; do
    # Skip if argument doesn't start with --
    if [[ ! "$1" =~ ^-- ]]; then
        shift
        continue
    fi
    
    case $1 in
        --port) PORT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

PORT=${PORT:-8080}

log "Running container on port $PORT"

log "Ensuring that the init directory exists"
mkdir -p /opt/dcv/init-$PORT

log "Making sure the init.sh file exists."
touch /opt/dcv/init-$PORT/init.sh

log "Copying the default init.sh file to the init directory"
cat /opt/dcv/dcv-init.sh > /opt/dcv/init-$PORT/init.sh

log "Setting the permissions"
chmod +x /opt/dcv/init-$PORT/init.sh

log "Setting the owner"
chown -R ubuntu:docker /opt/dcv/init-$PORT

log "Running the container"
docker run -d --rm --gpus all --privileged \
    -p $PORT:8443 \
    --name dcv-$PORT \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -v /opt/dcv/init-$PORT/init.sh:/var/lib/dcv/init.sh \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/dcv/usersession.xauth \
    dcv-server

log "Waiting for the container to start"
while ! docker ps | grep -q "dcv-8080"; do
    log "Waiting for the container to start"
    sleep 2
done

log "Waiting for the dcv server session to start"

for i in {1..5}; do
    if docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
        break
    fi
    sleep 2
done

while ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; do
    sleep 2
done

log "Waiting for the dcv server session to stop"
for i in {1..5}; do    
    if ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
        break
    fi
    sleep 2
done

log "Creating the dcv server session if it doesn't exist"
if ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
    docker exec dcv-$PORT dcv create-session \
        --init=/var/lib/dcv/init.sh \
        --type=virtual \
        --storage-root=%home% \
        --owner "user" \
        --user "user" \
        "usersession"
fi

log "Waiting for the dcv server session to start"
while ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; do
    sleep 2
done

log "Session created"