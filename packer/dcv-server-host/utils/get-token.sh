#! /bin/bash

export TOKEN_DEV="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MzcxMDYsImV4cCI6MTc0MDY0NzkwNiwicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.tx_wQzL-RsNj6bEcn2Clg3-ftafQsugHgY3089v4H6M"


# {
#   "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MTE1MjMsImV4cCI6MTc0MDYyMjMyMywicm9sZXMiOlsidXNlciJdLCJ0eXBlIjoiYWNjZXNzIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.MXdBmGr7n8TNLYX7ZDHSoUhbIAxErBAWUncVxV1gBNs",
#   "expiration": 1740622323,
#   "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJlMTk3Mjk2NS1iYTVhLTRiYmItYTJhMS1jODgwOTRiNWUzZGYiLCJpYXQiOjE3NDA2MTE1MjMsImV4cCI6MTc0MTIxNjMyMywicm9sZXMiOlsidXNlciJdLCJ1bmlxdWVJZCI6IjU4NzgzNzBiLTQ3MjAtNDQ2Yy1iZDU5LTRjNjFlYzUyMDdhZCIsInR5cGUiOiJyZWZyZXNoIiwiaXNzIjoiaHR0cDovL2NvcmUtYXBpLWRldi5pbnRyYXZlcnNlLmNvbSJ9.N1t14dFmss3D5BV3tMZsdTtX2B0my_OLe7fSpYKa05I",
#   "refreshExpiresAt": 1741216323
# }

# Get the token for the DCV server
curl -X 'POST' \
  'https://core-api-dev.intraverse.com/core-api/web/users/auth-session' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "userId": "e1972965-ba5a-4bbb-a2a1-c88094b5e3df"
}' | jq -r '.token'

TOKEN=$(curl -X 'POST' \
  'https://core-api-dev.intraverse.com/core-api/web/users/auth-session' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "userId": "e1972965-ba5a-4bbb-a2a1-c88094b5e3df"
}' | jq -r '.token')

echo $TOKEN