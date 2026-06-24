#!/bin/bash
KC="http://127.0.0.1:8180"

# Get admin token
RESP=$(curl -s -X POST "$KC/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password")
TOKEN=$(echo "$RESP" | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")

if [ -z "$TOKEN" ]; then
  echo "ERROR getting admin token: $RESP"
  exit 1
fi
echo "Admin token OK"

# Get user1 ID
USERS=$(curl -s "$KC/admin/realms/monitoring/users?username=user1" \
  -H "Authorization: Bearer $TOKEN")
USER_ID=$(echo "$USERS" | python3 -c "import sys,json; lst=json.load(sys.stdin); print(lst[0]['id'] if lst else '')")

if [ -z "$USER_ID" ]; then
  echo "ERROR: user1 not found. Users: $USERS"
  exit 1
fi
echo "user1 ID: $USER_ID"

# Remove required actions
HTTP=$(curl -s -o /tmp/fix_resp.txt -w "%{http_code}" -X PUT \
  "$KC/admin/realms/monitoring/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"requiredActions":[],"emailVerified":true,"enabled":true}')
echo "Update user: HTTP $HTTP - $(cat /tmp/fix_resp.txt)"

# Test token
echo "Testing user1 login..."
LOGIN=$(curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password")
ACCESS=$(echo "$LOGIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token','ERROR: '+d.get('error_description','unknown')))")

if echo "$ACCESS" | grep -q "^ERROR"; then
  echo "Login FAILED: $ACCESS"
else
  echo "Login OK! Token (${#ACCESS} chars)"
  echo "$ACCESS" > /tmp/jwt_token.txt
  echo "Saved to /tmp/jwt_token.txt"
fi
