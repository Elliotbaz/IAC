#! /bin/bash

# Prepare the environment

/usr/local/bin/cm-prepare-env.sh \
    --user-id e1972965-ba5a-4bbb-a2a1-c88094b5e3df \
    --auth-token eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MzcxMDYsImV4cCI6MTc0MDY0NzkwNiwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.tx_wQzL-RsNj6bEcn2Clg3-ftafQsugHgY3089v4H6M \
    --environment-type \
    --user-device-type \
    --max-players 0 \
    --port 8080 \
    --active-session-min-count 0 \
    --room-id string \
    --display-layout 1520x826+0+0 \
    --api-environment-type \
    --api-local-environment-url \
    --avatar-preset \
    --launch-url \
    --websocket-url

curl -X 'POST'   'https://render.intraversedev.com/api/v2/environment'   -H 'accept: application/json'   -H 'Content-Type: application/json'   -d '{
  "active_session_min_count": 0,
  "api_environment_type": "string",
  "api_local_environment_url": "string",
  "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MzcxMDYsImV4cCI6MTc0MDY0NzkwNiwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.tx_wQzL-RsNj6bEcn2Clg3-ftafQsugHgY3089v4H6M",
  "avatar_preset": "string",
  "disable_camera_mouse_rotation": false,
  "disable_text_chat": false,
  "disable_voice_chat": false,
  "display_layout": "1520x826+0+0",
  "environment_type": "aux",
  "is_private_room": false,
  "launch_url": "string",
  "max_players": 0,
  "network_mode": 5,
  "port": 8080,
  "restrict_network_to_device": false,
  "room_id": "string",
  "show_debugger": false,
  "user_device_type": "aux",
  "user_id": "e1972965-ba5a-4bbb-a2a1-c88094b5e3df",
  "websocket_url": "string"
}'

docker run -d --rm --gpus all --privileged \
    -p 8080:8443 \
    --name dcv-8080 \
    --add-host=metadata.aws.internal:169.254.169.254 \
    --add-host=metadata:169.254.169.254 \
    -v /opt/dcv/game-build:/var/lib/dcv/Desktop \
    -v /opt/dcv/init-8080/:/var/lib/dcv/init/ \
    -e DISPLAY=:1 \
    -e XAUTHORITY=/run/dcv/usersession.xauth \
    dcv-server