#!/bin/bash

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/dcv/init.log
    # echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
}

log "================================================"
log "Starting DCV Game Script"
log "================================================"

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
export DISPLAY=:1

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# Set the correct XAUTHORITY
export XAUTHORITY=/run/dcv/usersession.xauth
log "Using Xauthority file: $XAUTHORITY"

# Check X server
log 'Checking X server'
xdpyinfo_output=$(xdpyinfo)
if [ $? -eq 0 ]; then
    log "Top 10 lines of xdpyinfo output:"
    log "$xdpyinfo_output" | head -n 10
    log "..."
    log "Bottom 10 lines of xdpyinfo output:"
    log "$xdpyinfo_output" | tail -n 10
else
    log 'Failed to get display info'
fi

log 'Changing to Desktop directory' 
cd /var/lib/dcv/Desktop

log "Current directory: $(pwd)"
log 'Checking GPU status'
glxinfo | grep "OpenGL renderer" || log "Failed to get OpenGL renderer info"
nvidia-smi

log 'Launching game'

# Use optirun or primusrun if available
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

LAUNCH_COMMAND="$LAUNCH_PREFIX ./IntraverseClient.x86_64"
LAUNCH_COMMAND="$LAUNCH_COMMAND -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTA2OTliZC03NmUxLTQ0NzctOThmZC1jZGM1YzQxMWIxODEiLCJpYXQiOjE3MzY3OTI1MzIsImV4cCI6MTczNjgwMzMzMiwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.zoaRN3o1XS_RickUnfQFND3VIZDYS_T1euBykW2r4oU"
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



log "Launch command: $LAUNCH_COMMAND"

# Launch the game in the background and disown it
$LAUNCH_COMMAND > /var/log/game.log 2>&1 &
GAME_PID=$!

# Wait a short time to ensure the game starts
sleep 5

# Check if process is running
if ps -p $GAME_PID > /dev/null; then
    log "Game successfully launched with PID: $GAME_PID"
    log "Game logs available in /var/log/game.log"
else
    log "Game failed to start"
    exit 1
fi

log 'Script completed at' $(date)
log "================================================"

exit 0
