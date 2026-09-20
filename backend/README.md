# backend

Monolito modular hexagonal de finanzia (Python 3.12, FastAPI, arq). Ver [`docs/specs/003-architecture`](../docs/specs/003-architecture/spec.md).

Estado: Fase 0 (fundaciones) y Fase 1 (identity + ledger básico + bus de eventos) implementadas en la rama `CristianmMst/backend-architecture-setup`. Pendiente: app Flutter (F0.6, F1.9) y Fases 2+ (parsing, Gmail, fiscal, producción).

## 1. Prerrequisitos

- [Python 3.12](https://www.python.org/) (el proyecto fija `>=3.12,<3.13`).
- [uv](https://docs.astral.sh/uv/) como gestor de paquetes/entornos.
- Docker Desktop (Postgres 16 + Redis 7 vía `docker-compose.dev.yml`). En Windows, con WSL2 backend.
- `just` (opcional): recetas en el [`justfile`](../justfile) de la raíz del repo. Si no está instalado, cada receta es un comando `uv run ...` de una línea — se pueden correr directo.

## 2. Setup

Desde `backend/` (Windows: PowerShell o Git Bash):

```sh
cp .env.example .env
docker compose -f docker-compose.dev.yml up -d --wait
uv sync --all-groups
uv run alembic upgrade head
```

- `.env` nunca se commitea (está en `.gitignore`); ajusta ahí los valores para desarrollo local (ver tabla de variables en §8).
- `docker compose ... --wait` espera a que Postgres/Redis pasen su healthcheck antes de continuar.
- `alembic upgrade head` aplica las migraciones existentes: `0001_identity` (users, refresh_tokens) y `0002_ledger_core` (linked_accounts, categories + seed de 24 categorías del sistema, transactions, transaction_sources, merchant_rules).

## 3. Correr la aplicación

```sh
uv run uvicorn finanzia.main:app --reload
```

API en `http://localhost:8000`. En otra terminal, el worker de eventos (arq):

```sh
uv run arq finanzia.worker.WorkerSettings
```

El worker arranca el observador `ledger-observer`, que consume `TransactionCaptured` desde Redis Streams y solo loguea metadatos (nunca montos ni comercios, spec 009 §5).

### Perfil `app` de Docker Compose

Para levantar API + worker también en contenedores (imagen construida desde el `Dockerfile` del backend), junto con Postgres/Redis:

```sh
docker compose -f docker-compose.dev.yml --profile app up -d --build
```

Esto agrega los servicios `api` (puerto 8000) y `worker` al `up` normal de infra. Sin `--profile app`, `docker compose up` solo levanta Postgres y Redis (el flujo de desarrollo habitual, con la API corriendo local vía `uv run uvicorn`).

## 4. Comandos de calidad

```sh
uv run ruff check .          # lint
uv run ruff format --check . # formato
uv run pyright                # tipos (modo standard; strict en shared/*/domain/*/application)
uv run lint-imports            # fronteras entre modulos (import-linter, 6 contratos)
uv run pytest -q               # toda la suite (unit + integration + ci)
```

Gate de cobertura de dominio (≥90 %, exigido en CI para `ledger.domain` e `identity.domain`):

```sh
uv run pytest tests/unit -m unit --cov=finanzia.modules.ledger.domain --cov=finanzia.modules.identity.domain --cov-fail-under=90
```

También disponibles como recetas de [`just`](../justfile) desde la raíz del repo: `just lint`, `just test`, `just test-unit`, `just coverage-domain`, `just ci` (= `lint` + `test` + `coverage-domain`), `just migrate`, `just revision <nombre>`, `just up`/`down`, `just dev`, `just worker`.

## 5. Estructura de tests

```
tests/
├── conftest.py       # fixtures compartidas (session/function scope)
├── support/          # helpers (AuthedUser, factories)
├── unit/<modulo>/     # dominio puro + fakes; marker `unit`, sin Docker
├── integration/<modulo>/  # contra Postgres/Redis reales; marker `integration`
└── ci/                # contratos de pipeline (workflow, import-linter); marker `ci`
```

Markers (`pyproject.toml`, `--strict-markers`): `unit` (sin infraestructura), `integration` (requiere DB/Redis), `ci` (verifica el propio pipeline). `pytest-asyncio` en modo `auto`, loop de fixtures y de tests con scope `session`.

Bases de datos de test (separadas de las de desarrollo):
- `finanzia_test`: usada por la mayoría de tests de integración (fixture `migrated_db`, que corre `alembic upgrade head` una vez por sesión en un hilo aparte).
- `finanzia_test_migrations`: usada solo por `tests/integration/test_migrations.py` para probar el ciclo completo de migraciones (`upgrade`/`downgrade`) sin interferir con la DB que ya usan el resto de tests.
- Redis: base de datos lógica `1` (`redis://localhost:6379/1`), separada de la `0` de desarrollo; se limpia con `FLUSHDB` entre tests (fixture `redis_clean`).

Overrides por variable de entorno (útiles en CI o si tus puertos locales difieren):

| Variable | Uso |
|---|---|
| `FINANZIA_TEST_DATABASE_URL` | URL de `finanzia_test` (default `postgresql+asyncpg://finanzia:finanzia@localhost:5432/finanzia_test`) |
| `FINANZIA_TEST_REDIS_URL` | URL de Redis db 1 (default `redis://localhost:6379/1`) |
| `FINANZIA_TEST_MIGRATIONS_DATABASE_URL` | URL de `finanzia_test_migrations`, usada solo por el test de ciclo de migraciones |

Fixtures principales de `tests/conftest.py`: `settings` (session; `env=test`, apunta a `finanzia_test`/Redis db 1, `google_verifier=fake`, límites de rate limit altos por defecto para no interferir con el resto de la suite); `migrated_db`; `db_clean` (limpia datos de usuario entre tests sin `TRUNCATE`, preservando el seed de categorías del sistema); `redis_clean`; `app`/`client` (app FastAPI + `httpx.AsyncClient` con lifespan real vía `asgi-lifespan`); `fixed_clock`; `user_factory`/`second_user` (login real contra la API con el verificador fake); `access_token_expired`. El tiempo siempre se inyecta vía `ClockPort` (nunca `freezegun` ni `datetime.now()` directo). Los dobles de prueba (fakes) viven en `tests/unit/<modulo>/fakes.py`.

## 6. Arquitectura del código

```
backend/
├── src/finanzia/
│   ├── app.py               # composition root: crea la app FastAPI (routers, middlewares, lifespan)
│   ├── main.py               # entrypoint ASGI (uvicorn)
│   ├── worker.py             # composition root del worker arq (consumers de eventos + supervisor)
│   ├── events_registry.py    # registro de eventos de dominio conocidos, compartido por app.py y worker.py
│   ├── shared/                # kernel: config (pydantic-settings), db (SQLAlchemy async), security (JWT/hashing),
│   │                          # http (middlewares: rate limit, idempotency, request-id, body-limit, headers, health),
│   │                          # events (codec, adapter Redis Streams, consumer, handler idempotente), errors, logging
│   └── modules/<modulo>/     # identity, ingestion, parsing, ledger, fiscal, insights
│       ├── domain/            # entidades + lógica pura (sin FastAPI/SQLAlchemy/red)
│       ├── application/       # casos de uso; dependen de ports (interfaces)
│       ├── infrastructure/    # adapters: repos SQLAlchemy, routers FastAPI (infrastructure/api/)
│       ├── events.py          # eventos de dominio del módulo (puro, solo stdlib)
│       └── public.py          # API pública que otros módulos pueden importar
└── migrations/                 # Alembic, fuera del paquete `finanzia`
```

Import-linter (`uv run lint-imports`) verifica 6 contratos (`pyproject.toml`, sección `[tool.importlinter]`):

1. **R1** — `domain` no importa nada fuera de sí mismo y de la stdlib.
2. **R2** — `application` importa solo `domain`, sus propios `ports` y el `events.py` de su propio módulo.
3. **R3a** — `events.py` es puro (solo stdlib).
4. **R3b** — capas hexagonales por módulo: `infrastructure` → `application` → `domain` (nunca al revés).
5. **R4** — los módulos son independientes entre sí salvo por `public.py`/`events.py` (hoy el único cruce real es `ledger.infrastructure.api.deps` → `identity.public`).
6. **Kernel** — `shared` nunca importa `modules` ni los composition roots (`app`, `main`, `worker`, `events_registry`).

## 7. Login local sin GCP (verificador fake)

Con `FINANZIA_GOOGLE_VERIFIER=fake` (y `FINANZIA_ENV` distinto de `prod`, que lo prohíbe), `POST /v1/auth/google` acepta tokens sintéticos con el formato `fake:<sub>:<email>[:unverified[:<nombre>]]` en vez de un `id_token` real de Google. Útil para probar el flujo de login en desarrollo sin credenciales de Google Cloud.

```sh
curl -X POST http://localhost:8000/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "fake:demo:demo@example.com"}'
```

La respuesta trae `access_token`, `refresh_token`, `expires_in` y `user`. El acceso se usa como `Authorization: Bearer <access_token>` en el resto de endpoints autenticados.

## 8. Recorrido de la API (curl)

Con la API corriendo en `http://localhost:8000` y `FINANZIA_GOOGLE_VERIFIER=fake`:

```sh
# 1. Login (fake)
curl -s -X POST http://localhost:8000/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "fake:demo:demo@example.com"}'
# -> guarda access_token y refresh_token de la respuesta

TOKEN="<access_token de arriba>"
REFRESH="<refresh_token de arriba>"

# 2. Perfil propio
curl -s http://localhost:8000/v1/me -H "Authorization: Bearer $TOKEN"

# 3. Crear una cuenta vinculada
curl -s -X POST http://localhost:8000/v1/accounts \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"bank": "bancolombia", "kind": "savings", "last4": "1234", "alias": "Ahorros"}'

# 4. Crear una transaccion manual (con Idempotency-Key)
curl -s -X POST http://localhost:8000/v1/transactions \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "Idempotency-Key: $(uuidgen)" \
  -d '{"amount": "45900.00", "direction": "debit", "occurred_at": "2026-09-18T14:30:00-05:00", "merchant": "Rappi"}'

# 5. Listar transacciones (paginado por cursor)
curl -s "http://localhost:8000/v1/transactions?limit=2" -H "Authorization: Bearer $TOKEN"
# -> repetir con &cursor=<next_cursor> de la respuesta anterior para la siguiente pagina

# 6. Editar la categoria de una transaccion
curl -s -X PATCH http://localhost:8000/v1/transactions/<id> \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"category_id": "<uuid de una categoria>"}'

# 7. Rotar el refresh token
curl -s -X POST http://localhost:8000/v1/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{\"refresh_token\": \"$REFRESH\"}"
```

Ver §11 de este README para una corrida real con las respuestas efectivamente obtenidas.

## 9. Bus de eventos

Redis Streams como bus interno (spec 003 §2.3), implementado en `shared/events/`:

- Cada tipo de evento se publica en su propio stream: `finanzia:events:<event_type>` (p. ej. `finanzia:events:ledger.TransactionCaptured`).
- Los consumers usan grupos de consumidores (`XREADGROUP`); el grupo del observador de Fase 1 es `ledger-observer`. Mensajes pendientes de un consumidor caído se reclaman con `XAUTOCLAIM`.
- Mensajes que superan el máximo de reintentos van a la DLQ `finanzia:events:dlq`.
- Todo handler pasa por un wrapper idempotente que marca `event_id` procesado por grupo en Redis con un TTL de 7 días (evita reprocesar reentregas at-least-once).
- Los consumers corren dentro del proceso worker arq (`uv run arq finanzia.worker.WorkerSettings`), cada uno bajo un supervisor que los reinicia si terminan por una excepción inesperada.
- Publicación post-commit sin outbox transaccional en el MVP (riesgo aceptado, ver spec 003 §2.3 y roadmap §6).

## 10. Variables de entorno (`.env`)

Ver [`.env.example`](.env.example) — todas tienen el prefijo `FINANZIA_`:

| Variable | Significado |
|---|---|
| `FINANZIA_ENV` | Entorno de ejecución: `dev`, `test` o `prod` |
| `FINANZIA_DATABASE_URL` | URL asíncrona de Postgres (driver `asyncpg`) |
| `FINANZIA_REDIS_URL` | URL de Redis |
| `FINANZIA_JWT_SECRET` | Secreto para firmar JWT (≥32 caracteres; único por entorno real) |
| `FINANZIA_JWT_ACCESS_TTL_SECONDS` | TTL del access token, en segundos (default 900 = 15 min) |
| `FINANZIA_REFRESH_TTL_DAYS` | TTL deslizante del refresh token, en días (default 60) |
| `FINANZIA_GOOGLE_CLIENT_ID` | Client ID de Google OAuth para verificar `id_token` reales |
| `FINANZIA_GOOGLE_VERIFIER` | `"google"` (real) o `"fake"` (solo dev/test; prohibido si `FINANZIA_ENV=prod`) |
| `FINANZIA_LOG_LEVEL` | Nivel de logging: `DEBUG`, `INFO`, `WARNING` o `ERROR` |
| `FINANZIA_LOG_JSON` | Logs en JSON estructurado (default `true` salvo en `dev`) |
| `FINANZIA_TRUST_PROXY_HEADERS` | Confiar en `X-Forwarded-For`/proxy reverso (activar solo detrás de Caddy en producción) |
| `FINANZIA_RATE_LIMIT_AUTH_PER_MINUTE` | Límite de requests/min para `/auth/*` (por IP) |
| `FINANZIA_RATE_LIMIT_USER_PER_MINUTE` | Límite de requests/min por usuario autenticado (global) |
| `FINANZIA_IDEMPOTENCY_TTL_SECONDS` | TTL, en segundos, de las claves `Idempotency-Key` en Redis (default 86400 = 24 h) |
| `FINANZIA_MAX_BODY_BYTES` | Tamaño máximo aceptado del body de una request, en bytes |
| `FINANZIA_DB_POOL_SIZE` | Tamaño del pool de conexiones a la base de datos |
| `FINANZIA_DB_ECHO` | Loguear las sentencias SQL ejecutadas (nunca `true` en prod) |

## 11. Verificación (corrida real)

Ver el reporte de la Tarea 15 (`.superpowers/sdd/quiero-que-empieces-con-floofy-gray/task-15-report.md`) para la salida completa y actualizada de `ruff`/`pyright`/`lint-imports`/`pytest`/cobertura/`alembic check`/`docker build` y la corrida real del recorrido de curl de §8 contra una instancia local.
