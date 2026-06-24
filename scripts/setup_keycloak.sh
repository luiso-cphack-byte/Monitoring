#!/bin/bash
set -e

KC="http://127.0.0.1:8180"

echo "=== Obteniendo token de admin ==="
RESPONSE=$(curl -sf -X POST "$KC/realms/master/protocol/openid-connect/token" \
  -d "client_id=admin-cli&username=admin&password=admin&grant_type=password")
TOKEN=$(echo "$RESPONSE" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token',''))")

if [ -z "$TOKEN" ]; then
  echo "ERROR: No se pudo obtener token. Respuesta:"
  echo "$RESPONSE"
  exit 1
fi
echo "Token OK (${#TOKEN} chars)"

echo "=== Creando realm monitoring ==="
HTTP=$(curl -s -o /tmp/realm_resp.txt -w "%{http_code}" -X POST "$KC/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"realm":"monitoring","enabled":true,"registrationAllowed":false,"bruteForceProtected":true}')
echo "HTTP $HTTP: $(cat /tmp/realm_resp.txt)"

echo "=== Creando client monitoring-app ==="
HTTP=$(curl -s -o /tmp/client_resp.txt -w "%{http_code}" -X POST "$KC/admin/realms/monitoring/clients" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"clientId":"monitoring-app","publicClient":true,"directAccessGrantsEnabled":true,"enabled":true,"redirectUris":["http://localhost:4200/*"]}')
echo "HTTP $HTTP: $(cat /tmp/client_resp.txt)"

echo "=== Creando usuario user1 ==="
HTTP=$(curl -s -o /tmp/user_resp.txt -w "%{http_code}" -X POST "$KC/admin/realms/monitoring/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"username":"user1","enabled":true,"emailVerified":true,"credentials":[{"type":"password","value":"password123","temporary":false}]}')
echo "HTTP $HTTP: $(cat /tmp/user_resp.txt)"

echo "=== Verificando token de user1 ==="
RESP2=$(curl -sf -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
  -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password" 2>/dev/null || true)
USER_TOKEN=$(echo "$RESP2" | python3 -c "import sys,json; d=json.load(sys.stdin); print(d.get('access_token','ERROR'))" 2>/dev/null || echo "FAIL")

if [ "$USER_TOKEN" != "ERROR" ] && [ "$USER_TOKEN" != "FAIL" ] && [ -n "$USER_TOKEN" ]; then
  echo "Token de user1 OK (${#USER_TOKEN} chars)"
  echo "$USER_TOKEN" > /tmp/user_token.txt
  echo "Guardado en /tmp/user_token.txt"
else
  echo "ERROR obteniendo token de user1. Respuesta: $RESP2"
fi
