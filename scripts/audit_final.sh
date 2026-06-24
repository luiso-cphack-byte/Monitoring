#!/bin/bash
BACKEND="http://172.25.176.1:9090"
KC="http://127.0.0.1:8180"

echo "=== Token fresco ==="
TOKEN=$(curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password" \
  | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
LEN=${#TOKEN}
echo "Token: ${LEN} chars"

echo ""
echo "=== API con token válido ==="
CODE=$(curl -s -o /tmp/r.txt -w "%{http_code}" \
  -H "Authorization: Bearer $TOKEN" "$BACKEND/api/metrics")
echo "HTTP $CODE: $(cat /tmp/r.txt)"

echo ""
echo "=== JWT issuer en el token ==="
echo "$TOKEN" | cut -d. -f2 | python3 -c "
import sys, base64, json
s = sys.stdin.read().strip()
s += '=' * (-len(s) % 4)
d = json.loads(base64.urlsafe_b64decode(s))
print('  iss:', d.get('iss'))
print('  sub:', d.get('sub'))
print('  exp:', d.get('exp'))
print('  alg: RS256 (del header)')
"

echo ""
echo "=== GOBUSTER ==="
gobuster dir \
  -u "$BACKEND" \
  -w /usr/share/wordlists/dirb/common.txt \
  -t 20 -q \
  --timeout 5s \
  -b 401,404 2>&1 | head -20

echo ""
echo "=== Endpoints sensibles manuales ==="
for EP in /actuator /actuator/health /actuator/info /actuator/env \
          /actuator/beans /actuator/mappings /actuator/heapdump \
          /api /api/metrics /h2-console /swagger-ui.html \
          /v3/api-docs /admin /console /manager; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND$EP")
  [ "$CODE" != "000" ] && echo "  $EP → HTTP $CODE"
done
