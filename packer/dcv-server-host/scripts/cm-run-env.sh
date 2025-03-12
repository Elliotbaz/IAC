#!/bin/bash

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

# Write default values to a file
cat <<EOL > dcv_${PORT:-8080}.ini
GAME_MODE=${GAME_MODE:-true}
NETWORK_MODE=${NETWORK_MODE:-""}
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
DISPLAY_LAYOUT=${DISPLAY_LAYOUT:-null}
EOL

docker stop dcv-$PORT
docker run -d --rm --gpus all --privileged \
    -p $PORT:8443 \
    --name dcv-$PORT \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -v /dcv_$PORT.ini:/usr/local/bin/dcv.ini \
    -e DISPLAY=:1 \
    dcv-server
docker exec dcv-$PORT dcv

# Adjust the display layout
if [[ -n "$DISPLAY_LAYOUT" ]]; then
    docker exec $CONTAINER_ID dcv set-display-layout --session usersession $DISPLAY_LAYOUT
fi

# Prepare the command with only set arguments
CMD="/usr/local/bin/dcv-launch-game.sh"
[[ -n "$AUTH_TOKEN" ]] && CMD+=" --auth-token $AUTH_TOKEN"
[[ -n "$USER_ID" ]] && CMD+=" --user-id $USER_ID"
[[ -n "$NETWORK_MODE" ]] && CMD+=" --network-mode $NETWORK_MODE"
[[ -n "$ENVIRONMENT_TYPE" ]] && CMD+=" --environment-type $ENVIRONMENT_TYPE"
[[ -n "$API" ]] && CMD+=" --api $API"
[[ "$DISABLE_VOICECHAT" == "true" ]] && CMD+=" --disable-voicechat"
[[ "$RESTRICT_NETWORK_TO_DEVICE" == "true" ]] && CMD+=" --restrict-network-to-device"
[[ -n "$USER_DEVICE_TYPE" ]] && CMD+=" --user-device-type $USER_DEVICE_TYPE"
[[ "$MAX_PLAYERS" -gt 0 ]] && CMD+=" --max-players $MAX_PLAYERS"
[[ "$CONTAINER_PORT" != "8443" ]] && CMD+=" --port $CONTAINER_PORT"
[[ "$ACTIVE_SESSION_MIN_COUNT" -gt 0 ]] && CMD+=" --active-session-min-count $ACTIVE_SESSION_MIN_COUNT"
[[ "$DISABLE_TEXT_CHAT" == "true" ]] && CMD+=" --disable-text-chat"
[[ -n "$ROOM_ID" ]] && CMD+=" --room-id $ROOM_ID"
[[ "$SHOW_DEBUGGER" == "true" ]] && CMD+=" --show-debugger"
[[ "$IS_PRIVATE_ROOM" == "true" ]] && CMD+=" --is-private-room"
[[ -n "$API_ENVIRONMENT_TYPE" ]] && CMD+=" --api-environment-type $API_ENVIRONMENT_TYPE"
[[ -n "$API_LOCAL_ENVIRONMENT_URL" ]] && CMD+=" --api-local-environment-url $API_LOCAL_ENVIRONMENT_URL"
[[ -n "$AVATAR_PRESET" ]] && CMD+=" --avatar-preset $AVATAR_PRESET"
[[ -n "$LAUNCH_URL" ]] && CMD+=" --launch-url $LAUNCH_URL"
[[ "$DISABLE_CAMERA_MOUSE_ROTATION" == "true" ]] && CMD+=" --disable-camera-mouse-rotation"
[[ -n "$WEBSOCKET_URL" ]] && CMD+=" --websocket-url $WEBSOCKET_URL"

# Execute the command

docker exec $CONTAINER_ID $CMD

exit 0



/usr/local/bin/cm-prepare-env.sh --user-id 550699bd-76e1-4477-98fd-cdc5c411b181 --auth-token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiI1NTA2OTliZC03NmUxLTQ0NzctOThmZC1jZGM1YzQxMWIxODEiLCJpYXQiOjE3MzYyOTU5MjcsImV4cCI6MTczNjMwNjcyNywicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.qUiryD1qilShXDNURnBMqtVK7pMTvJpKBoYOLAk4ZSY --environment-type development --user-device-type desktop --port 8081 --api development --networkmode 5 --disablevoicechat false --restrictnetworktodevice false -websocketurl wzmqg11ywh.execute-api.us-east-1.amazonaws.com/dev