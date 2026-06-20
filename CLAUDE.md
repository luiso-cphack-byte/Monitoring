# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Monorepo structure

Three independently deployable services:
- `backend/` — Spring Boot 3.2 REST API (Java 17)
- `frontend/` — Angular 17 SPA (standalone components)
- `docker-compose.yml` — PostgreSQL 15 + Redis 7

## Commands

### Infrastructure
```bash
docker-compose up -d        # Start PostgreSQL and Redis
docker-compose down         # Stop
docker-compose down -v      # Stop and remove volumes
```

### Backend (`cd backend`)
```bash
mvn spring-boot:run         # Run dev server on :8080
mvn test                    # Run all tests
mvn test -Dtest=ClassName   # Run a single test class
mvn clean package           # Build JAR
```

### Frontend (`cd frontend`)
```bash
ng serve                    # Dev server on :4200
ng build                    # Production build → dist/
ng test                     # Unit tests (Karma)
ng generate component features/metrics/my-component --standalone
```

## Backend architecture

```
com.monitoring/
├── MonitoringApplication.java   # Entry point, @EnableCaching
├── config/
│   ├── CorsConfig.java          # Allows http://localhost:4200 on /api/**
│   └── RedisConfig.java         # RedisCacheManager, 10-min TTL, JSON serializer
├── controller/
│   └── MetricController.java    # REST CRUD → /api/metrics
├── model/
│   └── Metric.java              # JPA entity (id, name, value, unit, source, timestamp)
├── repository/
│   └── MetricRepository.java    # JpaRepository with findBySource / findByName
└── service/
    └── MetricService.java       # @Cacheable("metrics") on findAll, @CacheEvict on writes
```

Key wiring: `application.properties` reads `DB_USER`, `DB_PASS`, `REDIS_HOST`, `REDIS_PORT` from environment (`.env` file via Docker or OS env).

## Frontend architecture

```
src/app/
├── core/services/
│   └── metric.service.ts        # HttpClient wrapper for /api/metrics
├── features/metrics/
│   ├── metrics-list/            # Table view of all metrics
│   └── metric-form/             # Create / edit form
├── app.routes.ts                # /metrics, /metrics/new, /metrics/:id/edit
└── app.config.ts                # provideHttpClient, provideRouter
src/environments/
├── environment.ts               # apiUrl: http://localhost:8080
└── environment.prod.ts
```

## Adding a new entity

1. Create `model/MyEntity.java` (JPA `@Entity`, `Serializable`)
2. Create `repository/MyEntityRepository.java` (extends `JpaRepository`)
3. Create `service/MyEntityService.java` (add `@Cacheable` / `@CacheEvict` with a new cache name)
4. Create `controller/MyEntityController.java` (`@RequestMapping("/api/my-entities")`)
5. In Angular: add service in `core/services/`, add feature folder, register route
