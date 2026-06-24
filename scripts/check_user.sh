#!/bin/bash
KC="http://127.0.0.1:8180"

TOKEN=$(curl -s -X POST "$KC/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

echo "=== User1 details ==="
curl -s "$KC/admin/realms/monitoring/users?username=user1" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -m json.tool

echo ""
echo "=== Realm required actions defaults ==="
curl -s "$KC/admin/realms/monitoring/authentication/required-actions" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "
import sys,json
for x in json.load(sys.stdin):
    print(x['alias'], '| enabled:', x['enabled'], '| defaultAction:', x['defaultAction'])
"

echo ""
echo "=== Disable all default required actions ==="
# Get all required actions and disable the default ones
ACTIONS=$(curl -s "$KC/admin/realms/monitoring/authentication/required-actions" \
  -H "Authorization: Bearer $TOKEN")
echo "$ACTIONS" | python3 -c "
import sys,json
for x in json.load(sys.stdin):
    print(x['alias'])
" | while read ALIAS; do
  HTTP=$(curl -s -o /dev/null -w "%{http_code}" -X PUT \
    "$KC/admin/realms/monitoring/authentication/required-actions/$ALIAS" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "{\"alias\":\"$ALIAS\",\"defaultAction\":false,\"enabled\":true}")
  echo "  $ALIAS → HTTP $HTTP"
done

echo ""
echo "=== Re-creating user1 fresh ==="
USER_ID=$(curl -s "$KC/admin/realms/monitoring/users?username=user1" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; lst=json.load(sys.stdin); print(lst[0]['id'] if lst else '')")

# Delete old user
curl -s -o /dev/null -X DELETE "$KC/admin/realms/monitoring/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN"
echo "Deleted old user1"

# Recreate without required actions
HTTP=$(curl -s -o /tmp/new_user_resp.txt -w "%{http_code}" -X POST \
  "$KC/admin/realms/monitoring/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username":"user1",
    "enabled":true,
    "emailVerified":true,
    "requiredActions":[],
    "credentials":[{"type":"password","value":"password123","temporary":false}]
  }')
echo "Create new user1: HTTP $HTTP - $(cat /tmp/new_user_resp.txt)"

echo ""
echo "=== Test login ==="
LOGIN=$(curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password")
ACCESS=$(echo "$LOGIN" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token','FAIL: '+str(d))[:80])")
echo "Result: $ACCESS"
