# Monitoring

Dashboard genérico full-stack con Angular, Spring Boot, PostgreSQL y Redis.

## Servicios

| Servicio   | Tecnología         | Puerto |
|------------|--------------------|--------|
| Frontend   | Angular 17         | 4200   |
| Backend    | Spring Boot 3.2    | 8080   |
| Identidad  | Keycloak 24 (OIDC) | 8180   |
| Base datos | PostgreSQL 15      | 5432   |
| Caché      | Redis 7            | 6379   |

## Inicio rápido

### 1. Infraestructura (BD + Redis + Keycloak)

```bash
cp .env.example .env
docker-compose up -d
```

### 2. Configurar Keycloak (primera vez)

1. Abrir `http://localhost:8180` → Admin Console → login `admin / admin`
2. Crear realm: **monitoring**
3. Crear client: `monitoring-app` → Client authentication: OFF → Valid redirect URIs: `http://localhost:4200/*`
4. Crear usuario: `user1` → Credentials → password `password123` (temporary: OFF)

### 3. Backend

```bash
cd backend
mvn spring-boot:run
# Health check: GET http://localhost:8080/actuator/health
```

### 4. Frontend

```bash
cd frontend
npm install
ng serve
# App: http://localhost:4200
```

## Autenticación

Todos los endpoints `/api/**` requieren un JWT válido emitido por Keycloak.

**Obtener token (curl):**
```bash
curl -X POST http://localhost:8180/realms/monitoring/protocol/openid-connect/token \
  -d "grant_type=password&client_id=monitoring-app&username=user1&password=password123"
```

**Llamar a la API:**
```bash
curl -H "Authorization: Bearer <token>" http://localhost:8080/api/metrics
```

## Estructura

```
Monitoring/
├── backend/      # Spring Boot REST API
├── frontend/     # Angular SPA
└── docker-compose.yml
```

## API

Base URL: `http://localhost:8080/api`

| Método | Ruta            | Descripción          |
|--------|-----------------|----------------------|
| GET    | /metrics        | Listar métricas      |
| GET    | /metrics/{id}   | Obtener una métrica  |
| POST   | /metrics        | Crear métrica        |
| PUT    | /metrics/{id}   | Actualizar métrica   |
| DELETE | /metrics/{id}   | Eliminar métrica     |

Body de ejemplo:
```json
{
  "name": "cpu_usage",
  "value": 72.5,
  "unit": "%",
  "source": "server-01"
}
```
