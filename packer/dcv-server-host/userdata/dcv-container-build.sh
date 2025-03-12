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

# Install Xvfb
which Xvfb >/dev/null || sudo apt-get update && sudo apt-get install -y xvfb

# Create necessary directories for volume mounts
sudo mkdir -p /run/dcv
sudo touch /run/dcv/usersession-1.xauth
sudo touch /run/dcv/usersession-2.xauth
sudo chown 1000:1000 /run/dcv/usersession-*.xauth
sudo chmod 600 /run/dcv/usersession-*.xauth

# sudo mkdir -p /run/user/1000/dcv
# sudo mkdir -p /opt/dcv/game-build

# # Create the Xauthority file if it doesn't exist
# sudo touch /run/user/1000/dcv/usersession.xauth
# # Set ownership to UID 1000 (container user) and restrict permissions to user only
# sudo chown 1000:1000 /run/user/1000/dcv/usersession.xauth
# sudo chmod 600 /run/user/1000/dcv/usersession.xauth

sudo docker build -t dcv-base .
sudo docker build -t dcv-server --build-arg PORT=8443 -f Dockerfile.dcv .
#sudo docker build -v /run/user/1000/dcv/usersession.xauth:/run/user/1000/dcv/usersession.xauth -t dcv-server-8444 --build-arg PORT=8444 -f Dockerfile.dcv .

# PORT=8080



# sudo docker run --rm --gpus all --privileged \
#     -p $PORT:8443 \
#     --name dcv-$PORT \
#     --add-host=169.254.169.254:169.254.169.254 \
#     -v /tmp/.X11-unix:/tmp/.X11-unix \
#     -v /run/user/1000/dcv/usersession.xauth:/run/user/1000/dcv/usersession.xauth \
#     -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
#     -e DISPLAY=:1 \
#     -e XAUTHORITY=/run/user/1000/dcv/usersession.xauth \
#     dcv-server &

# sleep 10

# CID=$(sudo docker ps --format '{{.ID}}\t{{.Names}}' | awk -v port="$PORT" '$2 ~ "dcv-"port {count++; id=$1} END{if(count==1) print id; else exit 1}')
# log "Container ID: $CID"

# sudo docker stop $CID

log "Finished building DCV container."
