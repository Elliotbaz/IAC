#! /bin/bash

# Claim the environment

# curl -X 'POST' \
#   'https://render.intraversedev.com/api/v2/environment' \
#   -H 'accept: application/json' \
#   -H 'Content-Type: application/json' \
#   -d '{
#   "active_session_min_count": 0,
#   "api_environment_type": "string",
#   "api_local_environment_url": "string",
#   "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MTE1MjMsImV4cCI6MTc0MDYyMjMyMywicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.MXdBmGr7n8TNLYX7ZDHSoUhbIAxErBAWUncVxV1gBNs",
#   "avatar_preset": "string",
#   "disable_camera_mouse_rotation": false,
#   "disable_text_chat": false,
#   "disable_voice_chat": false,
#   "display_layout": "1520x826+0+0",
#   "environment_type": "aux",
#   "is_private_room": false,
#   "launch_url": "string",
#   "max_players": 0,
#   "network_mode": 5,
#   "port": 8080,
#   "restrict_network_to_device": false,
#   "room_id": "string",
#   "show_debugger": false,
#   "user_device_type": "aux",
#   "user_id": "e1972965-ba5a-4bbb-a2a1-c88094b5e3df",
#   "websocket_url": "string"
# }'

# {
#   "status": 200,
#   "message": "Existing environment found",
#   "data": [
#     {
#       "id": "67bf6ed25edc54b517c8bc80",
#       "name": "dcv-server-host-1.0.0-intraverse-0.1",
#       "description": "Environment on port 8080, running on machine i-0de3b040808b1b86b for user e1972965-ba5a-4bbb-a2a1-c88094b5e3df.",
#       "status": 0,
#       "ip": "3.94.108.234",
#       "created_at": "2025-02-26T19:43:14.153Z",
#       "updated_at": "2025-02-26T19:43:14.153Z",
#       "url": "",
#       "instance_id": "i-0de3b040808b1b86b",
#       "user_id": "e1972965-ba5a-4bbb-a2a1-c88094b5e3df",
#       "auth_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MTE1MjMsImV4cCI6MTc0MDYyMjMyMywicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.MXdBmGr7n8TNLYX7ZDHSoUhbIAxErBAWUncVxV1gBNs",
#       "network_mode": 0,
#       "restrict_network_to_device": false,
#       "environment_type": "",
#       "user_device_type": "",
#       "max_players": 0,
#       "port": 8080,
#       "active_session_min_count": 0,
#       "disable_text_chat": false,
#       "disable_voice_chat": false,
#       "room_id": "string",
#       "show_debugger": false,
#       "is_private_room": false,
#       "api_environment_type": "",
#       "api_local_environment_url": "",
#       "avatar_preset": "",
#       "launch_url": "",
#       "disable_camera_mouse_rotation": false,
#       "websocket_url": "",
#       "command_id": "",
#       "display_layout": "1520x826+0+0"
#     }
#   ]
# }