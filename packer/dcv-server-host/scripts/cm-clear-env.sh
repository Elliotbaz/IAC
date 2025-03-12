#!/bin/bash

# This is a cleanup script that will clear the init.sh file for the given port, kill the game on the container,
# close the DCV user session, and start up a new container with the default init.sh file to prepare for the next session.

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

# Set default value
PORT=${PORT:-8080}

# Overwrite the init.sh file with the default init.sh file
cat /opt/dcv/dcv-init.sh > /opt/dcv/init-$PORT/init.sh

# Set the permissions
chmod +x /opt/dcv/init-$PORT/init.sh

# Check if the container is running
if docker ps | grep -q "dcv-$PORT"; then
    # Kill the game on the container
    docker exec dcv-$PORT pkill -9 IntraverseClient.x86_64

    # Stop the DCV server session on the container
    docker exec dcv-$PORT dcv close-session usersession

    # Wait for the all sessions to be closed
    while docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; do
        sleep 1
    done
fi

# If the container is not running, run it with the default init.sh file so the next session will start faster
if ! docker ps | grep -q "dcv-$PORT"; then
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
fi

exit 0