#!/bin/bash
exec > >(tee -a /var/lib/dcv/init.log) 2>&1

echo 'Script started at $(date)'

# Set NVIDIA GPU as default
echo 'Setting NVIDIA GPU as default'
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DISPLAY=:0  # Ensure we're using the main display

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# Ensure necessary packages are installed
echo 'Checking and installing necessary packages'
apt-get update && apt-get install -y xorg openbox mesa-utils

# Check X server
echo 'Checking X server'
xdpyinfo || echo 'Failed to get display info'

# Start Openbox if not already running
if ! pgrep openbox > /dev/null; then
    echo 'Starting Openbox'
    openbox &
    sleep 2  # Give Openbox some time to start
else
    echo 'Openbox already running'
fi

echo 'Changing to Desktop directory' 
cd /var/lib/dcv/Desktop

echo 'Current directory: $(pwd)'
echo 'Checking GPU status'
glxinfo | grep "OpenGL renderer"
nvidia-smi

echo 'Launching game'

if [ ! -f "IntraverseClient.x86_64" ]; then
    echo 'Error: Game executable not found in $(pwd)'
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

# Launch the game with NVIDIA GPU and passed parameters
$LAUNCH_PREFIX ./IntraverseClient.x86_64 -authtoken eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI2ZWVlOWUzOC1jZjQ4LTQ4MmMtOTg3NS0zY2ZhNWRiYjcyMzciLCJpYXQiOjE3MjUwNDc0OTksImV4cCI6MTcyNTA1ODI5OSwicm9sZXMiOlsic3VwZXJhZG1pbiJdLCJpc3MiOiJodHRwOi8vY29yZS1hcGktZGV2LmludHJhdmVyc2UuY29tIn0.Ut0JdN6iIeDKygPM1nFUz0wnvUnqIW2Dkmr0yUFgA6A \
-userid 6eee9e38-cf48-482c-9875-3cfa5dbb7237 \
-networkmode 5 \
-environmenttype development \
-api development \
-disablevoicechat true \
-restrictnetworktodevice false \
-userdevicetype desktop

echo 'Game launched'
echo 'Script completed at $(date)'