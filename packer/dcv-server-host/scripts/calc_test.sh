#!/bin/bash

exec > >(tee -a /var/lib/dcv/init.log) 2>&1

echo "================================================"
echo "Starting DCV Game Script"
echo "================================================"

echo "Test script started at $(date)"

# Set NVIDIA GPU as default
echo 'Setting NVIDIA GPU as default'
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
export DISPLAY=:1

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# Set the correct XAUTHORITY
export XAUTHORITY=/run/user/1000/dcv/usersession.xauth
echo "Using Xauthority file: $XAUTHORITY"

# Check X server
echo 'Checking X server'
xdpyinfo_output=$(xdpyinfo)
if [ $? -eq 0 ]; then
    echo "Top 10 lines of xdpyinfo output:"
    echo "$xdpyinfo_output" | head -n 10
    echo "..."
    echo "Bottom 10 lines of xdpyinfo output:"
    echo "$xdpyinfo_output" | tail -n 10
else
    echo 'Failed to get display info'
fi

echo 'Changing to Desktop directory' 
cd /var/lib/dcv/Desktop

echo "Current directory: $(pwd)"
echo 'Checking GPU status'
glxinfo | grep "OpenGL renderer" || echo "Failed to get OpenGL renderer info"
nvidia-smi

echo 'Launching calculator'

# Use optirun or primusrun if available
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

echo "Launching game"
# $LAUNCH_PREFIX ./IntraverseClient.x86_64

$LAUNCH_PREFIX gnome-calculator

echo 'Game launched'
echo 'Script completed at' $(date)
echo "================================================"