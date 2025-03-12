#! /bin/bash

set -e

log() {
    # echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/userdata.log
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

log "================================================"
log "User data script started"
log "================================================"

# log "Install Xvfb if not present"
# which Xvfb >/dev/null || sudo apt-get update && sudo apt-get install -y xvfb

# Clean up any existing X servers or files
log "Cleaning up any existing X server processes, sockets, and files."
pkill Xvfb || true
rm -rf /tmp/.X*
rm -rf /run/dcv

log "Creating xauth files and directories"
mkdir -p /run/dcv
touch /run/dcv/usersession-1.xauth
touch /run/dcv/usersession-2.xauth
chown -R ubuntu:ubuntu /run/dcv
chmod 600 /run/dcv/usersession-*.xauth

log "First create the X11 directory as root"
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix

log "Then set up the auth file as ubuntu user"
sudo -u ubuntu xauth -f /run/dcv/usersession-1.xauth add :1 MIT-MAGIC-COOKIE-1 $(mcookie)

log "Then start Xvfb as root"
sudo -u ubuntu Xvfb :1 -auth /run/dcv/usersession-1.xauth -screen 0 1024x768x24 &

log "Wait for Xvfb to start for display :1"
for i in {1..5}; do
    if [ -e "/tmp/.X11-unix/X1" ]; then
        log "Xvfb started successfully"
        break
    fi
    if [ $i -eq 5 ]; then
        log "Xvfb failed to start"
        exit 1
    fi
    sleep 1
done

log "Set permissions for the X11 directory"
chmod 1777 /tmp/.X11-unix/X1

log "Set up second display :2"
sudo -u ubuntu xauth -f /run/dcv/usersession-2.xauth add :2 MIT-MAGIC-COOKIE-1 $(mcookie)
sudo -u ubuntu Xvfb :2 -auth /run/dcv/usersession-2.xauth -screen 0 1024x768x24 &

log "Wait for Xvfb to start for display :2"
for i in {1..5}; do
    if [ -e "/tmp/.X11-unix/X2" ]; then
        log "Xvfb started successfully"
        break
    fi
    if [ $i -eq 5 ]; then
        log "Xvfb failed to start"
        exit 1
    fi
    sleep 1
done

log "Set permissions for the X11 directory"
chmod 1777 /tmp/.X11-unix/X2

log "Verify file permissions"
log "X11 sockets: $(ls -l /tmp/.X11-unix)"
log "Xauth files: $(ls -l /run/dcv)"

log "Creating separate x11 socket directories for each container"
mkdir -p /tmp/x11-dcv-1/.X11-unix
mkdir -p /tmp/x11-dcv-2/.X11-unix
chmod 1777 /tmp/x11-dcv-1/.X11-unix
chmod 1777 /tmp/x11-dcv-2/.X11-unix

log "Linking the X sockets to the container directories"
ln -sf /tmp/.X11-unix/X1 /tmp/x11-dcv-1/.X11-unix/
ln -sf /tmp/.X11-unix/X2 /tmp/x11-dcv-2/.X11-unix/

log "Give symlinks time to propagate"
for i in {1..5}; do
    if [ -e "/tmp/x11-dcv-1/.X11-unix/X1" ] && [ -e "/tmp/x11-dcv-2/.X11-unix/X2" ]; then
        log "Symlinks propagated successfully"
        break
    fi
    sleep 1
done

log "Running container dcv-8080"
sudo -u ubuntu docker run -d --rm --gpus all --privileged \
    -p 8080:8443 \
    --name dcv-8080 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /tmp/x11-dcv-1/.X11-unix:/tmp/.X11-unix \
    -v /run/dcv/usersession-1.xauth:/run/user/1000/dcv/usersession.xauth \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/user/1000/dcv/usersession.xauth \
    dcv-server

log "Waiting for dcv-8080 to start"
sleep 5

log "Running container dcv-8081"
sudo -u ubuntu docker run -d --rm --gpus all --privileged \
    -p 8081:8443 \
    --name dcv-8081 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /tmp/x11-dcv-2/.X11-unix:/tmp/.X11-unix \
    -v /run/dcv/usersession-2.xauth:/run/user/1000/dcv/usersession.xauth \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/user/1000/dcv/usersession.xauth \
    dcv-server

log "Waiting for dcv-8081 to start"
sleep 2

log "Verifying containers"
log $(docker ps)

# Test X server access from containers
log "Testing X server access"
log $(docker exec dcv-8080 bash -c 'DISPLAY=:1 XAUTHORITY=/run/user/1000/dcv/usersession.xauth xdpyinfo')
log $(docker exec dcv-8081 bash -c 'DISPLAY=:1 XAUTHORITY=/run/user/1000/dcv/usersession.xauth xdpyinfo')


log "================================================"
log "User data script COMPLETED"
log "================================================"