#!/bin/bash


function log {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | sudo tee -a /var/lib/dcv/init.log
}

log "Init script started"

# Set NVIDIA GPU as default
log "Setting NVIDIA GPU as default"
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
# export DISPLAY=:1  # Ensure we're not using the main display

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# # Ensure necessary packages are installed
# echo 'Checking and installing necessary packages'
# apt-get update && apt-get install -y xorg openbox mesa-utils

# Check X server
log "Checking X server"
xdpyinfo_output=$(xdpyinfo)
if [ $? -eq 0 ]; then
    log "Top 10 lines of xdpyinfo output:"
    echo "$xdpyinfo_output" | head -n 10
    log "..."
    log "Bottom 10 lines of xdpyinfo output:"
    echo "$xdpyinfo_output" | tail -n 10
else
    log "Failed to get display info"
fi

# Start Openbox if not already running
if ! pgrep openbox > /dev/null; then
    log "Starting Openbox"
    openbox &
    sleep 2  # Give Openbox some time to start
else
    log "Openbox already running"
fi

log "Changing to Desktop directory"
cd /var/lib/dcv/Desktop

log "Current directory: $(pwd)"
log "Checking GPU status"
glxinfo | grep "OpenGL renderer"
log "nvidia-smi"

log "Launching game"

if [ ! -f "IntraverseClient.x86_64" ]; then
    log "Error: Game executable not found in $(pwd)"
    ls -l  # List directory contents for debugging
    exit 1
fi

# Use optirun or primusrun if available
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

# # Launch the game with NVIDIA GPU and passed parameters
# $LAUNCH_PREFIX ./IntraverseClient.x86_64 \
#     -userid 550699bd-76e1-4477-98fd-cdc5c411b181 \
#     -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTA2OTliZC03NmUxLTQ0NzctOThmZC1jZGM1YzQxMWIxODEiLCJpYXQiOjE3NDAwMDk1NDIsImV4cCI6MTc0MDAyMDM0Miwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.-VwVjEfuEu1Ytg7InqktarKp1ThIJQJUquQv4XtkMDQ \
#     -networkmode 5 \
#     -environmenttype aux \
#     -api development \
#     -disablevoicechat true \
#     -restrictnetworktodevice false \
#     -userdevicetype desktop

# Launch the game with NVIDIA GPU and passed parameters
$LAUNCH_PREFIX ./IntraverseClient.x86_64 \
    -userid e1972965-ba5a-4bbb-a2a1-c88094b5e3df \
    -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MTE1MjMsImV4cCI6MTc0MDYyMjMyMywicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.MXdBmGr7n8TNLYX7ZDHSoUhbIAxErBAWUncVxV1gBNs \
    -networkmode 5 \
    -environmenttype aux \
    -api development \
    -disablevoicechat true \
    -restrictnetworktodevice false \
    -userdevicetype desktop

log "Game launched"
log "Script completed at $(date)"