#!/bin/bash
KC="http://127.0.0.1:8180"
TOKEN=$(curl -s -X POST "$KC/realms/master/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin)['access_token'])")

USER_ID=$(curl -s "$KC/admin/realms/monitoring/users?username=user1" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -c "import sys,json; lst=json.load(sys.stdin); print(lst[0]['id'] if lst else '')")
echo "User ID: $USER_ID"

# Update user with complete profile (firstName, lastName, email required in KC24)
HTTP=$(curl -s -o /tmp/upd.txt -w "%{http_code}" -X PUT "$KC/admin/realms/monitoring/users/$USER_ID" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "username":"user1",
    "enabled":true,
    "emailVerified":true,
    "email":"user1@monitoring.local",
    "firstName":"User",
    "lastName":"One",
    "requiredActions":[]
  }')
echo "Update profile: HTTP $HTTP"
cat /tmp/upd.txt

# Test login
echo ""
echo "--- Test login ---"
RESP=$(curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password")
echo "$RESP" | python3 -c "
import sys, json
d = json.load(sys.stdin)
t = d.get('access_token', '')
if t:
    print('LOGIN OK - token ' + str(len(t)) + ' chars')
    with open('/tmp/jwt_token.txt', 'w') as f:
        f.write(t)
    print('Saved to /tmp/jwt_token.txt')
else:
    print('FAIL: ' + d.get('error_description', str(d)))
"
