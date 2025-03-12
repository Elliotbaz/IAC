#!/bin/bash

# This script will prepare a new environment for the DCV user.
# It will create a new init.sh file for the given port that contains the commands to start the game, including the user id,
# auth token, and other parameters that are passed to the game.

# It will then ensure that the container is running, that dcv server is running and clear out any existing sessions and 
# processes that should already be cleaned up from the clear script but could still be running if that script failed or 
# was not envoked.

# It will then start a new dcv session, launch the game with the parameters defined in the init.sh file, and set the display layout.

mkdir -p /var/log/dcv
touch /var/log/dcv/cm-prepare-env.log

function log() {
    echo $1
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/dcv/cm-prepare-env.log
}

log "================================================"
log "Starting CM Prepare Env Script"
log "================================================"

while [[ "$#" -gt 0 ]]; do
    # Skip if argument doesn't start with --
    if [[ ! "$1" =~ ^-- ]]; then
        shift
        continue
    fi
    
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
        --container-port) CONTAINER_PORT="$2"; shift ;;
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
        --display-layout) DISPLAY_LAYOUT="$2"; shift ;;
        *) echo "Unknown parameter passed: $1"; exit 1 ;;
    esac
    shift
done

# Set default values
GAME_MODE=${GAME_MODE:-true}
NETWORK_MODE=${NETWORK_MODE:-"5"}
RESTRICT_NETWORK_TO_DEVICE=${RESTRICT_NETWORK_TO_DEVICE:-false}
ENVIRONMENT_TYPE=${ENVIRONMENT_TYPE:-""}
USER_DEVICE_TYPE=${USER_DEVICE_TYPE:-""}
MAX_PLAYERS=${MAX_PLAYERS:-0}
PORT=${PORT:-8080}
CONTAINER_PORT=${CONTAINER_PORT:-8443}
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
DISPLAY_LAYOUT=${DISPLAY_LAYOUT:-"1520x826+0+0"}

log "Checking if the container is running"
if ! docker ps | grep -q "dcv-$PORT"; then
    log "Running the container"
    docker run -d --rm --gpus all --privileged \
        -p $PORT:8443 \
        --name dcv-$PORT \
        --add-host=metadata.aws.internal:169.254.169.254 \
        --add-host=metadata:169.254.169.254 \
        -e DISPLAY=:1 \
        -e XAUTHORITY=/run/dcv/usersession.xauth \
        dcv-server

    log "Waiting for dcv server session to be created"
    for i in {1..5}; do
        if docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
            break
        fi
        sleep 5
    done
fi

log "Ensuring that the init directory exists"
mkdir -p /opt/dcv/init-$PORT
cd /opt/dcv/init-$PORT

log "Creating the init.sh file"
touch init.sh

log "Setting the permissions"
chmod +x init.sh

log "Setting the owner"
chown -R ubuntu:docker /opt/dcv/init-$PORT

log "Writing the init.sh file"
cat > init.sh <<EOF
#!/bin/bash

echo "Clearing log" > /var/log/dcv/init.log

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') $1" >> /var/log/dcv/init.log
    # echo "$(date '+%Y-%m-%d %H:%M:%S') $1"
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

log "Using display: $DISPLAY"

# Additional NVIDIA-related environment variables
export VK_ICD_FILENAMES=/usr/share/vulkan/icd.d/nvidia_icd.json
export DRI_PRIME=1
export LD_LIBRARY_PATH=/usr/lib/nvidia:$LD_LIBRARY_PATH

####################################################

# # Set the correct XAUTHORITY
# export XAUTHORITY=/run/dcv/usersession.xauth
log "Using Xauthority file: $XAUTHORITY"

# Set XDG_RUNTIME_DIR
if [ -z "$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    mkdir -p \$XDG_RUNTIME_DIR
    chmod 0700 \$XDG_RUNTIME_DIR
    chown \$(id -u) \$XDG_RUNTIME_DIR
    log "Created XDG_RUNTIME_DIR at \$XDG_RUNTIME_DIR"
fi

log "XDG_RUNTIME_DIR: \$XDG_RUNTIME_DIR"

# Check X server
log 'Checking X server'
xdpyinfo_output=\$(xdpyinfo)
if [ \$? -eq 0 ]; then
    log "Top 10 lines of xdpyinfo output:"
    log "$xdpyinfo_output" | head -n 10
    log "..."
    log "Bottom 10 lines of xdpyinfo output:"
    log "$xdpyinfo_output" | tail -n 10
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

log "Current directory: $(pwd)"
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

LAUNCH_COMMAND="\$LAUNCH_PREFIX ./IntraverseClient.x86_64"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -authtoken $AUTH_TOKEN"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -userid $USER_ID"

LAUNCH_COMMAND="\$LAUNCH_COMMAND -networkmode $NETWORK_MODE"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -websocketurl wzmqg11ywh.execute-api.us-east-1.amazonaws.com/dev"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -environmenttype development"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -api development"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -disablevoicechat false"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -restrictnetworktodevice false"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -userdevicetype desktop"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -disablecameramouserotation true"

LAUNCH_COMMAND="\$LAUNCH_COMMAND -enableatomperformanceprofile false"
LAUNCH_COMMAND="\$LAUNCH_COMMAND -url https://www.dev.intraverse.com/ "

log "Setting XDG_RUNTIME_DIR"
if [ -z "\$XDG_RUNTIME_DIR" ]; then
    export XDG_RUNTIME_DIR=/run/user/$(id -u)
    mkdir -p \$XDG_RUNTIME_DIR
    chmod 0700 \$XDG_RUNTIME_DIR
    chown \$(id -u) \$XDG_RUNTIME_DIR
    log "Created XDG_RUNTIME_DIR at \$XDG_RUNTIME_DIR"
fi
log "XDG_RUNTIME_DIR: \$XDG_RUNTIME_DIR"
log "Launch command: \$LAUNCH_COMMAND"
\$LAUNCH_COMMAND
EOF

log "Checking if the container is running"
if docker ps | grep -q "dcv-$PORT"; then
    log "Stopping the game on the container"
    docker exec dcv-$PORT pkill -9 IntraverseClient.x86_64

    log "Stopping the DCV server session on the container"
    docker exec dcv-$PORT dcv close-session usersession

    log "Waiting for the all sessions to be closed"
    for i in {1..5}; do
        if ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
            break
        fi
        sleep 5
    done

    if docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; then
        log "Failed to close the session"
        exit 1
    fi

    log "Running the session start script"
    docker exec dcv-$PORT /usr/local/bin/dcv-start.sh

    # Copy the init.sh file to the container
    docker cp /opt/dcv/init-$PORT/init.sh dcv-$PORT:/var/lib/dcv/init.sh

    # Make sure the init.sh file is executable
    docker exec dcv-$PORT chmod +x /var/lib/dcv/init.sh

    # Make sure the init.sh file is owned by the dcv user
    docker exec dcv-$PORT chown dcv:dcv /var/lib/dcv/init.sh

    # Make sure the log file is owned by the dcv user
    docker exec dcv-$PORT chown dcv:dcv /var/log/dcv/init.log

    # docker exec dcv-$PORT /usr/local/bin/dcv-run.sh
    docker exec dcv-$PORT dcv create-session --init=/var/lib/dcv/init.sh --type=virtual --storage-root=%home% --owner "user" --user "user" "usersession"

    log "Waiting for the user session to be created"
    while ! docker exec dcv-$PORT dcv list-sessions | grep -q "usersession"; do
        sleep 1
    done

    log "Setting the display layout"
    docker exec dcv-$PORT dcv set-display-layout $DISPLAY_LAYOUT --session usersession
fi



exit 0
