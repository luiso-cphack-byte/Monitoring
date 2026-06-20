# Monitoring

Dashboard genérico full-stack con Angular, Spring Boot, PostgreSQL y Redis.

## Servicios

| Servicio   | Tecnología       | Puerto |
|------------|------------------|--------|
| Frontend   | Angular 17       | 4200   |
| Backend    | Spring Boot 3.2  | 8080   |
| Base datos | PostgreSQL 15    | 5432   |
| Caché      | Redis 7          | 6379   |

## Inicio rápido

### 1. Base de datos y caché

```bash
cp .env.example .env
docker-compose up -d
```

### 2. Backend

```bash
cd backend
mvn spring-boot:run
# Health check: GET http://localhost:8080/actuator/health
```

### 3. Frontend

```bash
cd frontend
npm install
ng serve
# App: http://localhost:4200
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
