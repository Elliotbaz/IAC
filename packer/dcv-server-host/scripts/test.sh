#!/bin/bash

###################################
# Reset init.sh to default
###################################

cat /opt/dcv/dcv-init.sh > /opt/dcv/init-8080/init.sh
cat /opt/dcv/dcv-init.sh > /opt/dcv/init-8081/init.sh

echo "" > /usr/local/bin/cm-containers-run.sh && vi /usr/local/bin/cm-containers-run.sh

###################################
# Run Docker Container
###################################

docker stop dcv-8080 dcv-8081

docker run -d --rm --gpus all --privileged \
    -p 8080:8443 \
    --name dcv-8080 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \

    -v /opt/dcv/init-8080/init.sh:/var/lib/dcv/init.sh \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/dcv/usersession.xauth \
    dcv-server

###################################
# Create DCV Session
###################################

docker exec dcv-8080 dcv create-session \
    --init=/var/lib/dcv/init.sh \
    --type=virtual \
    --storage-root=%home% \
    --owner "user" \
    --user "user" \
    "usersession"

docker exec dcv-8080 dcv create-session \
    --type=virtual \
    --storage-root=%home% \
    --owner "user" \
    --user "user" \
    "usersession"

###################################
# DCV Commands
###################################

docker exec dcv-8080 dcv list-sessions
docker exec dcv-8080 dcv close-session usersession
docker exec dcv-8080 dcv delete-session usersession

###########################################################################################################

###################################
# Run Docker Container
###################################

docker run -d --rm --gpus all --privileged \
    -p 8080:8443 \
    --name dcv-8080 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    dcv-server

docker run -d --rm --gpus all --privileged \
    -p 8081:8443 \
    --name dcv-8081 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    dcv-server

###################################
# Create DCV Session
###################################

dcv create-session \
    --type=virtual \
    --storage-root=%home% \
    --owner user \
    --user user \
    --init /usr/local/bin/init.sh \
    usersession

dcv create-session \
    --type=virtual \
    --storage-root=%home% \
    --owner "user" \
    --user user \
    --init /usr/local/bin/init.sh \
    usersession

###################################
# Run DCV Server
###################################

/usr/local/bin/cm-prepare-env.sh --user-id $UUID_JAY --auth-token $TOKEN_JAY \
    --environment-type \
    --user-device-type \
    --max-players 0 \
    --port 8080 \
    --active-session-min-count 0 \
    --room-id \
    --display-layout 1520x826+0+0 \
    --api-environment-type \
    --api-local-environment-url \
    --avatar-preset \
    --launch-url \
    --websocket-url

###################################
# Fix permissions and ownership of xauth and x socket
###################################

# Create xauth directory with correct ownership
mkdir -p /run/dcv
chown dcv:dcv /run/dcv
chmod 755 /run/dcv

# Create and set permissions for xauth file
touch /run/dcv/usersession.xauth
chown user:user /run/dcv/usersession.xauth
chmod 600 /run/dcv/usersession.xauth

# X11 socket directory
mkdir -p /tmp/.X11-unix
chmod 1777 /tmp/.X11-unix   # Sticky bit, world-writable

# Set ownership and permissions for init script
chown dcv:dcv /usr/local/bin/init.sh
chmod 755 /usr/local/bin/init.sh

# Create log directory with correct ownership
mkdir -p /var/log/dcv
chown dcv:dcv /var/log/dcv
chmod 755 /var/log/dcv

# Create (or ensure permissions on) the log file
touch /var/log/dcv/init.log
chown dcv:dcv /var/log/dcv/init.log
chmod 644 /var/log/dcv/init.log

###################################
# Prepare X server
###################################

# Kill any X-related processes
pkill Xvfb
pkill X
pkill Xorg

# Clean up ALL X11 sockets to be thorough
rm -rf /tmp/.X*

# Small pause to ensure cleanup is complete
sleep 2

# Create fresh xauth
xauth -f /run/dcv/usersession.xauth add :1 MIT-MAGIC-COOKIE-1 $(mcookie)

# Start Xvfb
Xvfb :1 -auth /run/dcv/usersession.xauth -screen 0 1024x768x24 &


#################################################
# Setup displays
#################################################

sudo /usr/local/bin/cm-setup-displays.sh


docker exec -it dcv-8080 pkill -9 -f IntraverseClient.x86_64
docker exec -it dcv-8081 pkill -9 -f IntraverseClient.x86_64

export TOKEN_JAY="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTA2OTliZC03NmUxLTQ0NzctOThmZC1jZGM1YzQxMWIxODEiLCJpYXQiOjE3NDAwMDk1NDIsImV4cCI6MTc0MDAyMDM0Miwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.-VwVjEfuEu1Ytg7InqktarKp1ThIJQJUquQv4XtkMDQ"
export TOKEN_DEV="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDAwMDI5NzEsImV4cCI6MTc0MDAxMzc3MSwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.F9WczE6TrBhnb2jWWHFecAdq68mpk_5bkz2kvygNRNQ"

sudo /usr/local/bin/cm-prepare-env.sh \
    --user-id 550699bd-76e1-4477-98fd-cdc5c411b181 \
    --auth-token $TOKEN_JAY \
    --environment-type \
    --user-device-type \
    --max-players 0 \
    --port 8080 \
    --active-session-min-count 0 \
    --room-id --api-environment-type --api-local-environment-url --avatar-preset --launch-url --websocket-url

/usr/local/bin/cm-prepare-env.sh \
    --user-id e1972965-ba5a-4bbb-a2a1-c88094b5e3df \
    --auth-token $TOKEN_DEV \
    --environment-type \
    --user-device-type \
    --max-players 0 \
    --port 8081 \
    --active-session-min-count 0 \
    --room-id --api-environment-type --api-local-environment-url --avatar-preset --launch-url --websocket-url

docker run -d --rm --gpus all --privileged \
    -p 8080:8443 \
    --name dcv-8080 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -v /opt/dcv/init-8080/init.sh:/var/lib/dcv/init.sh \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/dcv/usersession.xauth \
    dcv-server