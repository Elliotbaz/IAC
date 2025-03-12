#!/bin/bash

echo "Clearing log" > /var/log/dcv/init.log

log() {
    echo "2025-02-19 18:16:14 " >> /var/log/dcv/init.log
    # echo "2025-02-19 18:16:14 "
}

log "================================================"
log "Starting DCV Game Script"
log "================================================"

####################################################

# Kill any running pulseaudio processes
log "Checking and killing existing pulseaudio processes..."
if pgrep pulseaudio > /dev/null; then
    log "Pulseaudio processes found. Killing them now..."
    pkill -9 pulseaudio
    log "Pulseaudio processes killed."
else
    log "No pulseaudio processes running."
fi

# Set NVIDIA GPU as default
log 'Setting NVIDIA GPU as default'
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
# export DISPLAY=:1

log "Using display: "

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:

####################################################

# # Set the correct XAUTHORITY
# export XAUTHORITY=/run/dcv/usersession.xauth
log "Using Xauthority file: "

# Set XDG_RUNTIME_DIR
if [ -z "/run/user/1000" ]; then
    export XDG_RUNTIME_DIR=/run/user/1000
    mkdir -p $XDG_RUNTIME_DIR
    chmod 0700 $XDG_RUNTIME_DIR
    chown $(id -u) $XDG_RUNTIME_DIR
    log "Created XDG_RUNTIME_DIR at $XDG_RUNTIME_DIR"
fi

log "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"

# Check X server
log 'Checking X server'
xdpyinfo_output=$(xdpyinfo)
if [ $? -eq 0 ]; then
    log "Top 10 lines of xdpyinfo output:"
    log "" | head -n 10
    log "..."
    log "Bottom 10 lines of xdpyinfo output:"
    log "" | tail -n 10
else
    log 'Failed to get display info'
fi

# Start Openbox if not already running
if ! pgrep openbox > /dev/null; then
    echo 'Starting Openbox'
    openbox &
    sleep 2  # Give Openbox some time to start
else
    echo 'Openbox already running'
fi

log 'Changing to Desktop directory' 
cd /var/lib/dcv/Desktop

log "Current directory: /opt/dcv/init-8080"
log 'Checking GPU status'
glxinfo | grep "OpenGL renderer" || log "Failed to get OpenGL renderer info"
nvidia-smi

log 'Launching game'

log "Using optirun or primusrun if available"
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

LAUNCH_COMMAND="$LAUNCH_PREFIX ./IntraverseClient.x86_64"
LAUNCH_COMMAND="$LAUNCH_COMMAND -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTA2OTliZC03NmUxLTQ0NzctOThmZC1jZGM1YzQxMWIxODEiLCJpYXQiOjE3NDAwMDI1MzUsImV4cCI6MTc0MDAxMzMzNSwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.kIToycfRC2nqpNwdfoMEqPLPOYGY5pU0Vr6E5vY3X0o"
LAUNCH_COMMAND="$LAUNCH_COMMAND -userid 550699bd-76e1-4477-98fd-cdc5c411b181"

LAUNCH_COMMAND="$LAUNCH_COMMAND -networkmode 5"
LAUNCH_COMMAND="$LAUNCH_COMMAND -websocketurl wzmqg11ywh.execute-api.us-east-1.amazonaws.com/dev"
LAUNCH_COMMAND="$LAUNCH_COMMAND -environmenttype development"
LAUNCH_COMMAND="$LAUNCH_COMMAND -api development"
LAUNCH_COMMAND="$LAUNCH_COMMAND -disablevoicechat false"
LAUNCH_COMMAND="$LAUNCH_COMMAND -restrictnetworktodevice false"
LAUNCH_COMMAND="$LAUNCH_COMMAND -userdevicetype desktop"
LAUNCH_COMMAND="$LAUNCH_COMMAND -disablecameramouserotation true"

LAUNCH_COMMAND="$LAUNCH_COMMAND -enableatomperformanceprofile false"
LAUNCH_COMMAND="$LAUNCH_COMMAND -url https://www.dev.intraverse.com/ "

log "Setting XDG_RUNTIME_DIR"
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/1000
    mkdir -p $XDG_RUNTIME_DIR
    chmod 0700 $XDG_RUNTIME_DIR
    chown $(id -u) $XDG_RUNTIME_DIR
    log "Created XDG_RUNTIME_DIR at $XDG_RUNTIME_DIR"
fi
log "XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
log "Launch command: $LAUNCH_COMMAND"
$LAUNCH_COMMAND