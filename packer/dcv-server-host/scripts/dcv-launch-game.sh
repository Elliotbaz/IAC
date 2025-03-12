#!/bin/bash

exec > >(tee -a /var/lib/dcv/init.log) 2>&1

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --auth-token) AUTH_TOKEN="$2"; shift ;;
        --user-id) USER_ID="$2"; shift ;;
        --network-mode) NETWORK_MODE="$2"; shift ;;
        --environment-type) ENVIRONMENT_TYPE="$2"; shift ;;
        --api) API="$2"; shift ;;
        --disable-voicechat) DISABLE_VOICECHAT="$2"; shift ;;
        --restrict-network-to-device) RESTRICT_NETWORK_TO_DEVICE="$2"; shift ;;
        --user-device-type) USER_DEVICE_TYPE="$2"; shift ;;
        --max-players) MAX_PLAYERS="$2"; shift ;;
        --port) PORT="$2"; shift ;;
        --active-session-min-count) ACTIVE_SESSION_MIN_COUNT="$2"; shift ;;
        --disable-text-chat) DISABLE_TEXT_CHAT="$2"; shift ;;
        --room-id) ROOM_ID="$2"; shift ;;
        --show-debugger) SHOW_DEBUGGER="$2"; shift ;;
        --is-private-room) IS_PRIVATE_ROOM="$2"; shift ;;
        --api-environment-type) API_ENVIRONMENT_TYPE="$2"; shift ;;
        --api-local-environment-url) API_LOCAL_ENVIRONMENT_URL="$2"; shift ;;
        --avatar-preset) AVATAR_PRESET="$2"; shift ;;
        --launch-url) LAUNCH_URL="$2"; shift ;;
        --disable-camera-mouse-rotation) DISABLE_CAMERA_MOUSE_ROTATION="$2"; shift ;;
        --websocket-url) WEBSOCKET_URL="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Set default values
GAME_MODE=${GAME_MODE:-true}
NETWORK_MODE=${NETWORK_MODE:-""}
RESTRICT_NETWORK_TO_DEVICE=${RESTRICT_NETWORK_TO_DEVICE:-false}
ENVIRONMENT_TYPE=${ENVIRONMENT_TYPE:-""}
USER_DEVICE_TYPE=${USER_DEVICE_TYPE:-""}
MAX_PLAYERS=${MAX_PLAYERS:-0}
PORT=${PORT:-0}
ACTIVE_SESSION_MIN_COUNT=${ACTIVE_SESSION_MIN_COUNT:-0}
DISABLE_TEXT_CHAT=${DISABLE_TEXT_CHAT:-false}
DISABLE_VOICECHAT=${DISABLE_VOICECHAT:-false}
ROOM_ID=${ROOM_ID:-""}
SHOW_DEBUGGER=${SHOW_DEBUGGER:-false}
IS_PRIVATE_ROOM=${IS_PRIVATE_ROOM:-false}
API_ENVIRONMENT_TYPE=${API_ENVIRONMENT_TYPE:-""}
API_LOCAL_ENVIRONMENT_URL=${API_LOCAL_ENVIRONMENT_URL:-""}
AVATAR_PRESET=${AVATAR_PRESET:-""}
LAUNCH_URL=${LAUNCH_URL:-""}
DISABLE_CAMERA_MOUSE_ROTATION=${DISABLE_CAMERA_MOUSE_ROTATION:-false}
WEBSOCKET_URL=${WEBSOCKET_URL:-""}

echo "================================================"
echo "Starting DCV Game Script"
echo "================================================"

echo "Auth Token: $AUTH_TOKEN"
echo "User ID: $USER_ID"
echo "Network Mode: $NETWORK_MODE"
echo "Environment Type: $ENVIRONMENT_TYPE"
echo "API: $API"
echo "Disable Voice Chat: $DISABLE_VOICECHAT"
echo "Restrict Network to Device: $RESTRICT_NETWORK_TO_DEVICE"
echo "User Device Type: $USER_DEVICE_TYPE"

echo "Test script started at $(date)"

# Kill any running pulseaudio processes
echo "Checking and killing existing pulseaudio processes..."
if pgrep pulseaudio > /dev/null; then
    echo "Pulseaudio processes found. Killing them now..."
    pkill -9 pulseaudio
    echo "Pulseaudio processes killed."
else
    echo "No pulseaudio processes running."
fi

# Set NVIDIA GPU as default
echo 'Setting NVIDIA GPU as default'
export __NV_PRIME_RENDER_OFFLOAD=1
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export __VK_LAYER_NV_optimus=NVIDIA_only
# export DISPLAY=:1

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

# Set the correct XAUTHORITY
# export XAUTHORITY=/run/user/1000/dcv/usersession.xauth
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

echo 'Launching game'

# Use optirun or primusrun if available
if command -v optirun &> /dev/null; then
    LAUNCH_PREFIX="optirun"
elif command -v primusrun &> /dev/null; then
    LAUNCH_PREFIX="primusrun"
else
    LAUNCH_PREFIX=""
fi

# echo "Launching game"
# $LAUNCH_PREFIX ./IntraverseClient.x86_64 \
# -authtoken "$AUTH_TOKEN" \
# -userid "$USER_ID" 

echo "user id: $USER_ID"
echo "auth token: $AUTH_TOKEN"

LAUNCH_COMMAND="$LAUNCH_PREFIX ./IntraverseClient.x86_64"
LAUNCH_COMMAND="$LAUNCH_COMMAND -authtoken $AUTH_TOKEN"
LAUNCH_COMMAND="$LAUNCH_COMMAND -userid $USER_ID"

# LAUNCH_COMMAND="$LAUNCH_COMMAND -gamemode $GAME_MODE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -maxplayers $MAX_PLAYERS"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -port $PORT"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -activesessionmincount $ACTIVE_SESSION_MIN_COUNT"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -disabletextchat $DISABLE_TEXT_CHAT"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -roomid $ROOM_ID"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -showdebugger $SHOW_DEBUGGER"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -isprivateroom $IS_PRIVATE_ROOM"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -apienvironmenttype $API_ENVIRONMENT_TYPE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -apilocalenvironmenturl $API_LOCAL_ENVIRONMENT_URL"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -avatarpreset $AVATAR_PRESET"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -launchurl $LAUNCH_URL"

# LAUNCH_COMMAND="$LAUNCH_COMMAND -networkmode $NETWORK_MODE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -websocketurl $WEBSOCKET_URL"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -environmenttype $ENVIRONMENT_TYPE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -api $API"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -disablevoicechat $DISABLE_VOICECHAT"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -restrictnetworktodevice $RESTRICT_NETWORK_TO_DEVICE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -userdevicetype $USER_DEVICE_TYPE"
# LAUNCH_COMMAND="$LAUNCH_COMMAND -disablecameramouserotation $DISABLE_CAMERA_MOUSE_ROTATION"

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



echo "Launch command: $LAUNCH_COMMAND"

# Launch the game in the background and disown it
$LAUNCH_COMMAND > /var/log/game.log 2>&1 &
GAME_PID=$!

# Wait a short time to ensure the game starts
sleep 5

# Check if process is running
if ps -p $GAME_PID > /dev/null; then
    echo "Game successfully launched with PID: $GAME_PID"
    echo "Game logs available in /var/log/game.log"
else
    echo "Game failed to start"
    exit 1
fi

echo 'Script completed at' $(date)
echo "================================================"

exit 0