# backend

Monolito modular hexagonal de luka (Python 3.12, FastAPI, arq). Ver [`docs/specs/003-architecture`](../docs/specs/003-architecture/spec.md). El despliegue en producción (VPS compartido con Docker Compose detrás de su nginx, desde GitHub Actions) está en [`deploy/README.md`](deploy/README.md).

Estado: Fase 0 (fundaciones) y Fase 1 (identity + ledger básico + bus de eventos) mergeadas a `main`. Fase 2 (pipeline de captura y parsing, solo Bancolombia — F2.1–F2.6) también en `main`. La app Flutter (F0.6, F1.9) inicia sesión con Google real contra esta API. Fase 3 (Gmail, F3.1–F3.6) está en la rama local `f3-gmail`: watch/sync, cifrado del refresh token, endpoints de conexión, webhook y paso de onboarding en la app, verificado en modo de prueba de Google con túnel de desarrollo (§16). Pendiente: F2.7 (bancos restantes, diferido), la verificación DKIM del remitente (spec 009 §1) y Fases 5+ (fiscal, producción).

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

- `.env` nunca se commitea (está en `.gitignore`); trae solo las 4 variables obligatorias; el resto tiene default (ver §10).
- `docker compose ... --wait` espera a que Postgres/Redis pasen su healthcheck antes de continuar.
- `alembic upgrade head` aplica las migraciones existentes: `0001_identity` (users, refresh_tokens) y `0002_ledger_core` (linked_accounts, categories + seed de 24 categorías del sistema, transactions, transaction_sources, merchant_rules).

## 3. Correr la aplicación

```sh
uv run uvicorn luka.main:app --reload
```

API en `http://localhost:8000`. En otra terminal, el worker de eventos (arq):

```sh
uv run arq luka.worker.WorkerSettings
```

El worker arranca el observador `ledger-observer`, que consume `TransactionCaptured` desde Redis Streams y solo loguea metadatos (nunca montos ni comercios, spec 009 §5).

### Docker Compose solo levanta infraestructura

`docker-compose.dev.yml` levanta únicamente Postgres y Redis. La API (`just dev`) y el worker (`just worker`) siempre corren locales, así usan el código y el `.env` del momento. Un contenedor lee el `.env` solo al crearse y su imagen queda con el código de cuando se construyó. El perfil `app`, que corría API y worker en contenedores, se retiró el 2026-09-23 por eso: un contenedor viejo con el client ID de ejemplo rechazaba el login con 401.

## 4. Comandos de calidad

```sh
uv run ruff check .          # lint
uv run ruff format --check . # formato
uv run pyright                # tipos (modo standard; strict en shared/*/domain/*/application)
uv run lint-imports            # fronteras entre modulos (import-linter, 6 contratos)
uv run pytest -q               # toda la suite (unit + integration + ci)
```

Gate de cobertura de dominio (≥90 %, se corre en local antes de subir, para `ledger.domain`, `identity.domain`, `parsing.domain` e `ingestion.domain`):

```sh
uv run pytest tests/unit -m unit --cov=luka.modules.ledger.domain --cov=luka.modules.identity.domain --cov=luka.modules.parsing.domain --cov=luka.modules.ingestion.domain --cov-fail-under=90
```

También disponibles como recetas de [`just`](../justfile) desde la raíz del repo: `just lint`, `just test`, `just test-unit`, `just coverage-domain`, `just ci` (= `lint` + `test` + `coverage-domain`), `just migrate`, `just revision <nombre>`, `just up`/`down`, `just dev`, `just worker` y `just reparse [--since AAAA-MM-DD]` (reprocesa los mensajes `failed` con cuerpo y cierra su revisión como `reparsed`; corre `just migrate` antes si falta la 0007 y necesita el worker en marcha, spec 005 §7) y `just mark-self-transfers [--user UUID]` (marca como transferencia los envíos y recibos ya capturados al propio titular, sin tocar los editados a mano; imprime `marked=<n> skipped_edited=<m>`, spec 004 §4.1).

## 5. Estructura de tests

```
tests/
├── conftest.py       # fixtures compartidas (session/function scope)
├── support/          # helpers (AuthedUser, factories, email_fixtures.py, pipeline.py)
├── fixtures/emails/   # correos bancarios reales anonimizados (ver §11.4)
├── unit/<modulo>/     # dominio puro + fakes; marker `unit`, sin Docker
├── integration/<modulo>/  # contra Postgres/Redis reales; marker `integration`
│   └── pipeline/        # F2.9: pipeline e2e ingestion→parsing→ledger sobre Redis Streams reales
└── ci/                # contratos de pipeline (workflow, import-linter, higiene de logs); marker `ci`
```

Markers (`pyproject.toml`, `--strict-markers`): `unit` (sin infraestructura), `integration` (requiere DB/Redis), `ci` (verifica el propio pipeline). `pytest-asyncio` en modo `auto`, loop de fixtures y de tests con scope `session`.

Bases de datos de test (separadas de las de desarrollo):
- `luka_test`: usada por la mayoría de tests de integración (fixture `migrated_db`, que corre `alembic upgrade head` una vez por sesión en un hilo aparte).
- `luka_test_migrations`: usada solo por `tests/integration/test_migrations.py` para probar el ciclo completo de migraciones (`upgrade`/`downgrade`) sin interferir con la DB que ya usan el resto de tests.
- Redis: base de datos lógica `1` (`redis://localhost:6379/1`), separada de la `0` de desarrollo; se limpia con `FLUSHDB` entre tests (fixture `redis_clean`).

Overrides por variable de entorno (útiles en CI o si tus puertos locales difieren):

| Variable | Uso |
|---|---|
| `LUKA_TEST_DATABASE_URL` | URL de `luka_test` (default `postgresql+asyncpg://luka:luka@localhost:5432/luka_test`) |
| `LUKA_TEST_REDIS_URL` | URL de Redis db 1 (default `redis://localhost:6379/1`) |
| `LUKA_TEST_MIGRATIONS_DATABASE_URL` | URL de `luka_test_migrations`, usada solo por el test de ciclo de migraciones |

Fixtures principales de `tests/conftest.py`: `settings` (session; `env=test`, apunta a `luka_test`/Redis db 1, límites de rate limit altos por defecto para no interferir con el resto de la suite); `migrated_db`; `db_clean` (limpia datos de usuario entre tests sin `TRUNCATE`, preservando el seed de categorías del sistema); `redis_clean`; `app`/`client` (app FastAPI creada con `create_test_app` + `httpx.AsyncClient` con lifespan real vía `asgi-lifespan`); `fixed_clock`; `user_factory`/`second_user` (login real contra la API; `tests/support/google_stub.py` inyecta `StubGoogleIdTokenVerifier`, que acepta tokens `stub:<sub>:<email>[:unverified[:<nombre>]]` sin llamar a Google. Es solo de tests: la API no tiene modo simulado); `access_token_expired`. El tiempo siempre se inyecta vía `ClockPort` (nunca `freezegun` ni `datetime.now()` directo). Los dobles de prueba (fakes) viven en `tests/unit/<modulo>/fakes.py`.

## 6. Arquitectura del código

```
backend/
├── src/luka/
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
└── migrations/                 # Alembic, fuera del paquete `luka`
```

Import-linter (`uv run lint-imports`) verifica 6 contratos (`pyproject.toml`, sección `[tool.importlinter]`):

1. **R1** — `domain` no importa nada fuera de sí mismo y de la stdlib.
2. **R2** — `application` importa solo `domain`, sus propios `ports` y el `events.py` de su propio módulo.
3. **R3a** — `events.py` es puro (solo stdlib).
4. **R3b** — capas hexagonales por módulo: `infrastructure` → `application` → `domain` (nunca al revés).
5. **R4** — los módulos son independientes entre sí salvo por `public.py`/`events.py`; cada cruce concreto está listado explícitamente en `ignore_imports` (`pyproject.toml`), p. ej. `ledger.infrastructure.api.deps` → `identity.public`, `ingestion.infrastructure.sender_policy` → `parsing.public` (allowlists de captura, D6), `parsing.infrastructure.raw_message_gateway` → `ingestion.public` (leer el cuerpo de un `raw_message`, D2), `ledger.infrastructure.raw_messages_gateway` → `ingestion.public` (resolver `/review`, D1) y `ledger.infrastructure.consumers` → `parsing.events` (consumir `TransactionParsed`/`ParseFailed`).
6. **Kernel** — `shared` nunca importa `modules` ni los composition roots (`app`, `main`, `worker`, `events_registry`).

## 7. Login con Google

`POST /v1/auth/google` verifica siempre el `id_token` contra Google: firma, `iss`, `exp` y que `aud` sea `LUKA_GOOGLE_CLIENT_ID` (cliente web, el de Android) o `LUKA_GOOGLE_IOS_CLIENT_ID` (en iOS Google emite el token para el cliente iOS). No hay modo simulado. El login se hace desde la app Flutter (`app/README.md`, `just app-run` con el backend corriendo).

La respuesta trae `access_token`, `refresh_token`, `expires_in` y `user`. El acceso se usa como `Authorization: Bearer <access_token>` en el resto de endpoints autenticados.

Para los recorridos curl de §8 y §11 hace falta un `id_token` real emitido para el client ID web. Una forma de obtenerlo es el [OAuth 2.0 Playground](https://developers.google.com/oauthplayground):
1. En ⚙ activa *Use your own OAuth credentials* con el client ID y el secreto del cliente web.
2. En la consola, agrega `https://developers.google.com/oauthplayground` como URI de redireccionamiento del cliente web.
3. Autoriza el scope `openid email profile` con un usuario de prueba y copia el `id_token` de la respuesta.

## 8. Recorrido de la API (curl)

Con la API corriendo en `http://localhost:8000` y un `id_token` real de Google (§7):

```sh
# 1. Login
curl -s -X POST http://localhost:8000/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "<id_token de Google>"}'
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

- Cada tipo de evento se publica en su propio stream: `luka:events:<event_type>` (p. ej. `luka:events:ledger.TransactionCaptured`).
- Los consumers usan grupos de consumidores (`XREADGROUP`). Mensajes pendientes de un consumidor caído se reclaman con `XAUTOCLAIM`.
- Mensajes que superan el máximo de reintentos van a la DLQ `luka:events:dlq`.
- Todo handler pasa por un wrapper idempotente que marca `event_id` procesado por grupo en Redis con un TTL de 7 días (evita reprocesar reentregas at-least-once).
- Los consumers corren dentro del proceso worker arq (`uv run arq luka.worker.WorkerSettings`), cada uno bajo un supervisor que los reinicia si terminan por una excepción inesperada.
- Publicación post-commit sin outbox transaccional en el MVP (riesgo aceptado, ver spec 003 §2.3 y §12.5 de este README).
- Los grupos se crean (idempotente, `XGROUP CREATE ... $ MKSTREAM`) tanto al arrancar la API como el worker, para que un evento publicado antes del primer arranque del worker no se pierda.

Eventos y grupos de consumidores (Fase 1 + Fase 2):

| Evento | Publica | Grupo consumidor | Consume | Efecto |
|---|---|---|---|---|
| `ledger.TransactionCaptured` | ledger | `ledger-observer` | worker (observador) | solo loguea metadatos (F1.8) |
| `ingestion.RawMessageReceived` | ingestion | `parsing` | worker (parsing) | dispara `ParseRawMessage` (F2.2) |
| `parsing.TransactionParsed` | parsing | `ledger` | worker (ledger) | dedupe + inserta transacción (F2.5) |
| `parsing.ParseFailed` | parsing | `ledger-review` | worker (ledger) | encola en `review_queue` (F2.6) |

El worker (F2.2/F2.9) arranca 4 consumers bajo supervisor (uno por combinación evento/grupo de la tabla, salvo `ledger-observer` que ya existía en Fase 1) más 2 cron jobs: `purge_raw_message_bodies` (diario 08:00 UTC = 03:00 en Colombia; `arq` agenda contra el reloj del proceso y el contenedor corre en UTC) y `requeue_pending_raw_messages` (cada 15 min) — ver §12.

## 10. Variables de entorno (`.env`)

Todas tienen el prefijo `LUKA_`. Solo las 6 marcadas como **obligatoria** van en [`.env.example`](.env.example); el resto tiene default en `src/luka/shared/settings.py` y se define únicamente para cambiarlo:

| Variable | Significado |
|---|---|
| `LUKA_ENV` | Entorno de ejecución: `dev` (default), `test` o `prod` |
| `LUKA_DATABASE_URL` | **Obligatoria.** URL asíncrona de Postgres (driver `asyncpg`) |
| `LUKA_REDIS_URL` | **Obligatoria.** URL de Redis |
| `LUKA_JWT_SECRET` | **Obligatoria.** Secreto para firmar JWT (≥32 caracteres; único por entorno real) |
| `LUKA_JWT_ACCESS_TTL_SECONDS` | TTL del access token, en segundos (default 900 = 15 min) |
| `LUKA_REFRESH_TTL_DAYS` | TTL deslizante del refresh token, en días (default 60) |
| `LUKA_GOOGLE_CLIENT_ID` | **Obligatoria.** Client ID web de Google OAuth: audiencia del `id_token` en Android y cliente con el que se canjea el `serverAuthCode` (dev: proyecto `luka-510204`) |
| `LUKA_GOOGLE_IOS_CLIENT_ID` | **Obligatoria.** Client ID OAuth de iOS; también se acepta como `aud` del `id_token`, porque en iOS Google lo emite para ese cliente |
| `LUKA_GOOGLE_CLIENT_SECRET` | **Obligatoria (Fase 3).** Secreto del cliente OAuth web; canjea el `serverAuthCode` de Gmail en `POST /gmail/connect` |
| `LUKA_GMAIL_TOKEN_KEY` | **Obligatoria (Fase 3).** 32 bytes aleatorios en base64 (`openssl rand -base64 32`) para cifrar con AES-256-GCM el refresh token de Gmail (`gmail_connections.refresh_token_enc`, spec 009 §3). En `prod` se rechaza la llave de ejemplo de `.env.example` |
| `LUKA_GMAIL_PUBSUB_TOPIC` | **Obligatoria.** Topic de Pub/Sub al que se suscribe `users.watch` (dev: `projects/luka-510204/topics/gmail-push`) |
| `LUKA_GMAIL_PUSH_AUDIENCE` | **Obligatoria.** Audiencia (`aud`) exigida al token OIDC del webhook `POST /webhooks/gmail`; es la configurada en la suscripción push (dev: `luka-gmail-push`; no cambia con la URL, ver §16) |
| `LUKA_GMAIL_PUSH_SERVICE_ACCOUNT` | **Obligatoria.** Cuenta de servicio (`email`) exigida al mismo token OIDC (dev: `gmail-push-invoker@luka-510204.iam.gserviceaccount.com`) |
| `LUKA_LOG_LEVEL` | Nivel de logging: `DEBUG`, `INFO`, `WARNING` o `ERROR` |
| `LUKA_LOG_JSON` | Logs en JSON estructurado (default `true` salvo en `dev`) |
| `LUKA_TRUST_PROXY_HEADERS` | Confiar en `X-Forwarded-For`/proxy reverso (activar solo detrás del nginx de producción) |
| `LUKA_RATE_LIMIT_AUTH_PER_MINUTE` | Límite de requests/min para `/auth/*` (por IP) |
| `LUKA_RATE_LIMIT_USER_PER_MINUTE` | Límite de requests/min por usuario autenticado (global) |
| `LUKA_IDEMPOTENCY_TTL_SECONDS` | TTL, en segundos, de las claves `Idempotency-Key` en Redis (default 86400 = 24 h) |
| `LUKA_MAX_BODY_BYTES` | Tamaño máximo aceptado del body de una request, en bytes |
| `LUKA_DB_POOL_SIZE` | Tamaño del pool de conexiones a la base de datos |
| `LUKA_DB_ECHO` | Loguear las sentencias SQL ejecutadas (nunca `true` en prod) |
| `LUKA_RATE_LIMIT_INGEST_PER_MINUTE` | Límite de requests/min por usuario para `/v1/ingest/*` (regla `ingest_user`, F2.1, spec 009 §4), además del límite global |
| `LUKA_DEEPSEEK_API_KEY` | API key de DeepSeek (LLM de parsing). Vacía → adapter `DisabledLlmParser`, todo mensaje sin plantilla cae a revisión con `reason=llm_disabled` (legítimo también en prod) |
| `LUKA_DEEPSEEK_BASE_URL` | URL base de la API de DeepSeek (compatible OpenAI) |
| `LUKA_DEEPSEEK_MODEL` | Modelo usado para el parseo por LLM (`deepseek-v4-flash`) |
| `LUKA_LLM_TIMEOUT_SECONDS` | Timeout, en segundos, de las llamadas HTTP a DeepSeek |
| `LUKA_LLM_MONTHLY_TOKEN_BUDGET_PER_USER` | Presupuesto mensual de tokens LLM por usuario (Redis, clave `llm:budget:{user_id}:{YYYYMM}`, spec 006 §4.2) |
| `LUKA_LLM_CONFIDENCE_THRESHOLD` | Umbral mínimo de `confidence` del LLM para aceptar una extracción (0, 1] |
| `LUKA_RAW_MESSAGE_RETENTION_DAYS` | Días de retención del cuerpo de un mensaje crudo antes de que el cron de purga lo anule (spec 004 §6) |
| `LUKA_RAW_MESSAGE_BODY_MAX_BYTES` | Tamaño máximo, en bytes, del cuerpo persistido de un mensaje crudo (spec 006 §2.3) |

## 11. Recorrido de la API (curl) — Fase 2: ingesta, parsing y revisión

Continuación de §8 (misma sesión, mismo `$TOKEN`). Requiere el worker corriendo (§12.2) además de
la API, porque el parseo ocurre de forma asíncrona en el proceso worker.

```sh
# 8. Ingerir una notificación bancaria de Bancolombia (compra con tarjeta débito)
curl -s -X POST http://localhost:8000/v1/ingest/notifications \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{
    "items": [{
      "package": "com.bancolombia.app",
      "channel": "notification",
      "posted_at": "2026-09-20T16:00:00-05:00",
      "title": "Compra aprobada",
      "text": "Bancolombia: Compraste $176.824,00 en CARBON Y XILVESTRE T con tu T.Deb *1234, el 20/09/2026 a las 16:00",
      "client_hash": "'"$(echo -n demo-compra-1 | sha256sum | cut -d' ' -f1)"'"
    }]
  }'
# -> {"accepted": 1, "duplicates": 0, "discarded": 0}

# 9. Esperar a que el worker la procese (regex de plantilla, sin LLM) y consultarla
curl -s "http://localhost:8000/v1/transactions?limit=5" -H "Authorization: Bearer $TOKEN"
# -> la transacción aparece con parsed_by: "rule:bancolombia:compra_tdeb:v1"

# 10. Config remota de captura para el cliente Android (F4.3, backend ya hecho)
curl -s http://localhost:8000/v1/config/capture -H "Authorization: Bearer $TOKEN"

# 11. Cola de revisión (vacía si todo se parseó por regla)
curl -s http://localhost:8000/v1/review -H "Authorization: Bearer $TOKEN"

# 12. Ingerir un texto monetario que NINGUNA plantilla reconoce -> cae al LLM
#     (llm_disabled en dev sin LUKA_DEEPSEEK_API_KEY) -> review_queue
curl -s -X POST http://localhost:8000/v1/ingest/notifications \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{
    "items": [{
      "package": "com.bancolombia.app",
      "channel": "notification",
      "posted_at": "2026-09-20T16:05:00-05:00",
      "title": "Movimiento",
      "text": "Bancolombia: recibiste un giro internacional por $500.000,00 el 20/09/2026",
      "client_hash": "'"$(echo -n demo-review-1 | sha256sum | cut -d' ' -f1)"'"
    }]
  }'

curl -s http://localhost:8000/v1/review -H "Authorization: Bearer $TOKEN"
# -> item con reason: "llm_disabled" (guarda el raw_message_id de la respuesta)

# 13. Convertir el item de revisión en una transacción manual
curl -s -X POST http://localhost:8000/v1/review/<raw_message_id>/convert \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -d '{"amount": "500000.00", "direction": "credit", "occurred_at": "2026-09-20T16:05:00-05:00", "merchant": "Giro internacional"}'
# -> 201, parsed_by: "manual", sources[0].raw_message_id = el mensaje crudo
```

Ver §14 para una corrida real de este recorrido con las respuestas efectivamente obtenidas.

## 12. Pipeline de captura y parsing (Fase 2)

Implementa spec 006 (captura y parsing) para el canal `POST /v1/ingest/notifications` (correo Gmail
llega en Fase 3). Solo Bancolombia tiene plantillas con fixture real (F2.3); los otros 5 bancos de
`senders.yaml` se aceptan en la ingesta pero, al no tener plantilla, siempre caen al LLM/revisión.

### 12.1 Módulos y flujo

- **`ingestion`**: filtra remitente/paquete (`parsing.public.bank_for_*`), persiste `raw_messages`
  (`pending`) y publica `RawMessageReceived`. Dueño de `POST /v1/ingest/notifications` y
  `GET /v1/config/capture`.
- **`parsing`**: consume `RawMessageReceived`, intenta una plantilla regex por banco
  (`parsing/config/templates/<banco>.yaml`) y, si no matchea, cae al LLM (DeepSeek, adapter en
  `parsing/infrastructure/llm/`). Publica `TransactionParsed` o `ParseFailed`. Ver spec 006 §4.
- **`ledger`**: consume `TransactionParsed` (dedupe + inserta, grupo `ledger`) y `ParseFailed`
  (inserta en `review_queue`, grupo `ledger-review`). Dueño de `GET /v1/review`,
  `POST /v1/review/{id}/convert` y `POST /v1/review/{id}/discard`.

### 12.2 Correr el worker y leer sus logs de arranque

```sh
uv run arq luka.worker.WorkerSettings
```

El `on_startup` del worker (composition root, `worker.py`) crea su propio engine de DB, cliente
`httpx.AsyncClient` y cliente Redis, arranca los 4 consumers de eventos bajo supervisor y registra
los 2 cron jobs. Logs de arranque relevantes:

- `worker_llm_status` (`enabled=<bool>`, `model=<modelo>`) — qué adapter de LLM quedó activo; nunca
  incluye la API key.
- `llm_disabled_no_api_key` (warning) — solo aparece si `LUKA_DEEPSEEK_API_KEY` está vacía: el
  adapter activo es `DisabledLlmParser` y todo mensaje sin plantilla regex terminará en
  `review_queue` con `reason=llm_disabled` (comportamiento esperado en dev/CI sin credenciales).
- `consumer_groups_not_ensured` (warning) — Redis no respondió a `ensure_consumer_groups` dentro del
  timeout; el worker sigue arrancando igual (fail-soft).

### 12.3 Fixtures y cómo añadir una plantilla de banco nueva

Fixtures de correos/notificaciones reales anonimizados en
[`tests/fixtures/emails/`](tests/fixtures/emails/README.md) (contrato del encabezado YAML, tabla de
fixtures existentes y sus patrones). **Regla de oro (spec 006 §4.1): ninguna plantilla entra sin un
fixture de mensaje real anonimizado.** Para añadir un banco/plantilla nuevos:

1. Conseguir un mensaje real del banco, anonimizarlo (montos, últimos dígitos, nombres) preservando
   comercio/remitente/estructura/formato de fecha y monto.
2. Agregarlo como fixture en `tests/fixtures/emails/<banco>/<caso>.txt` (encabezado YAML + `---` +
   cuerpo), con su bloque `expected`.
3. Si el banco no está en `parsing/config/senders.yaml`, agregarlo (`verified: true` solo si hay
   fixture real que lo confirme).
4. Agregar/editar la entrada en `parsing/config/templates/<banco>.yaml` (patrón regex con grupos
   nombrados, `date_format`, `direction`, `suggested_category` opcional) siguiendo el esquema de
   spec 006 §4.1.
5. Test unitario en `tests/unit/parsing/test_templates_<banco>.py` que verifique la extracción
   contra el fixture, más el test de integración de pipeline
   (`tests/integration/pipeline/test_email_fixtures_to_transaction.py`) si aplica.
6. Documentar el fixture en `tests/fixtures/emails/README.md`.

### 12.4 Métrica del pipeline

Un evento de log estructurado `parsing_metric` por resultado (nunca datos crudos del mensaje, P1):
desde `parsing` con claves `outcome, bank, channel, template_id, reason, llm_tokens`
(`outcome ∈ {parsed_by_rule, parsed_by_llm, sent_to_review, discarded}`); desde `ingestion` con
`outcome ∈ {accepted, duplicate, discarded}` + `channel, bank, reason, republished`. Ver spec 006 §6.
No hay agregación en base de datos ni dashboard en Fase 2 — los contadores se calculan agregando
logs.

### 12.5 Riesgos conocidos (heredados del plan de Fase 2, §4)

- **Sin outbox transaccional**: el evento de salida se publica antes del commit del estado del
  `raw_message` (D8, `event_id` determinista absorbe reentregas); el hueco "commit del estado ok,
  publish falla" lo cierra el cron `requeue_pending_raw_messages` (cada 15 min, filas `pending` con
  más de 10 min sin tocar). El reencolado está acotado: `raw_messages.requeue_attempts` cuenta las
  republicaciones y a la sexta la fila pasa a `failed` en vez de volver al stream, para que un
  mensaje que falla siempre no rebote entre el cron y la DLQ para siempre. No hay outbox
  transaccional real; propuesto para una fase futura si un caso de uso lo exige.
- **`llm_error` → revisión inmediata** (D11): una caída de DeepSeek de minutos manda mensajes a
  revisión en vez de usar el reintento del consumer de Redis Streams. Elegido visibilidad sobre
  latencia; revisar con métricas tras Fase 3.
- **Cap de body de 1 MB por request** (`LUKA_MAX_BODY_BYTES`) en `/v1/ingest/notifications`:
  documentado como límite duro (spec 009 §4); un cliente con batches muy grandes debe paginar sus
  envíos.

## 13. Pendientes / deuda conocida (Fase 2)

Hallazgos menores identificados en revisiones de código de Fase 2 y diferidos a propósito (no
bloquean el cierre de F2.1–F2.6; quedan anotados aquí en vez de en un issue tracker externo):

- **Falta un índice `(status, updated_at)` en `raw_messages`** para la query global del cron
  `requeue_pending_raw_messages` (hoy solo existen `ix_raw_messages_user_id_status` e
  `ix_raw_messages_purge_after`); a añadir antes de que el volumen de filas `pending` lo justifique
  (candidato natural: junto con F3, cuando entre el volumen real de Gmail).
- **El camino HTTP real de DeepSeek nunca se ejercitó contra un endpoint vivo**: toda la cobertura
  de `parsing/infrastructure/llm/deepseek.py` usa `httpx.MockTransport`, y el recorrido de §14 corrió
  con el LLM deshabilitado (`enabled=False`, sin `LUKA_DEEPSEEK_API_KEY`). Lo verificado es la
  forma del request/respuesta y el mapeo de errores, no la interoperabilidad real con la API de
  DeepSeek (auth, `response_format: json_object`, límites de rate). Pendiente: una corrida manual con
  API key antes de habilitarlo en producción.
- **Retención de los streams de Redis**: los 90 días del job de purga solo aplican a
  `raw_messages.body` en Postgres. Los eventos `parsing.TransactionParsed`/`parsing.ParseFailed`
  llevan datos derivados (monto, comercio, `last4`, `partial_extract`) y sus streams —igual que la
  DLQ— solo se acotan por `MAXLEN ~100000`, no por tiempo: al volumen actual, en la práctica se
  conservan indefinidamente. El recorte por tiempo (`XTRIM ... MINID`) queda para Fase 3 (documentado
  en spec 004 §6).
- **Presupuesto mensual del LLM con clave de mes en UTC** (`parse_raw_message.py`, `now.strftime
  ("%Y%m")` sobre un reloj UTC): las últimas 5 horas de cada mes colombiano caen en el bucket del mes
  siguiente. Inocuo con el presupuesto actual; si alguna vez importa, usar `ZoneInfo
  ("America/Bogota")` para calcular la clave.
- **`_PHONE_RE` del extractor borra cualquier corrida de 10 dígitos** (`parsing/domain/excerpt.py`):
  con separadores opcionales, un número de referencia largo puede borrar la única línea con monto en
  la rama de fallback (sin `relevant_line_prefix`). No afecta a Bancolombia por email (tiene prefijo);
  a revisar cuando entren las plantillas de los demás bancos (F2.7).
- **`IngestNotificationsBatch` no aísla los items inválidos**: su docstring dice que un item malo no
  anula el resto, pero `validate_external_id` lanza desde `execute` y abortaría el batch. Hoy es
  inalcanzable vía API (el schema Pydantic valida antes), así que queda como docstring optimista a
  suavizar o a convertir en captura por item.
- **`POST /v1/ingest/notifications` consume dos cubetas de rate limit** (`ingest_user` 60/min y la
  global `user_global`): la interacción entre ambas no está documentada en spec 009 §4, así que el
  límite efectivo puede sorprender al cliente Android cuando suba un batch grande tras estar offline.
- **`parse_amount` interpreta `"45,9"` como `459.00`** (regla determinista heredada del plan: la coma
  es separador de miles en los formatos bancarios colombianos). Correcto para los fixtures reales,
  pero es una trampa si alguna vez llega un mensaje con coma decimal.
- **Minucias heredadas de las revisiones por tarea (T2/T4/T5/T7), sin efecto observable y diferidas
  en bloque**: conteo de campos en un reporte de tarea; el orden en que `IngestRawMessage` aplica
  `validate_external_id` respecto del filtro de remitente (un `external_id` inválido de un remitente
  no soportado hoy responde 400 en vez de descartarse); la aserción de la rama de carrera de
  `record_captured_transaction`, que comprueba el resultado agregado y no que se haya tomado esa
  rama; y nombres poco descriptivos (nombre de la dependencia de parsing en `pyproject.toml`, logger
  de `parsing/infrastructure/llm`).
- **Asimetría de fallback banco/canal en los consumers de ledger**
  (`ledger/infrastructure/consumers.py`): `Bank(event.bank)` cae a `Bank.OTHER` si el valor no está
  en el enum, pero `Channel(event.channel)` no tiene fallback equivalente (lanzaría `ValueError` si
  llegara un canal desconocido). Intencional por ahora — `channel` lo produce el propio backend, no
  un tercero — pero documentado como asimetría a revisar si `Channel` alguna vez se alimenta de un
  valor externo.
- **Fakes duplicados**: `FakeLlmParser`/`InMemoryBudget` existen tanto en `tests/unit/parsing/fakes.py`
  como (duplicados) en `tests/support/pipeline.py`, porque `tests/integration/pipeline` no comparte
  `sys.path` con `tests/unit` al correr en aislamiento — importar desde ahí rompería esa
  verificación. Se podría resolver moviendo los fakes compartidos a un paquete común instalable,
  pero no se justificaba solo por esto en F2.
- **El presenter de `/review` descarta en silencio items cuyo `raw_message` desapareció**
  (`ledger/infrastructure/api/presenters.py::review_entry_response` devuelve `None` si
  `entry.source is None`): caso defensivo (el FK es `CASCADE`, no debería ocurrir en la práctica),
  pero hoy no deja rastro en logs; falta un log de advertencia para poder detectarlo si llega a
  pasar.
- **`worker.on_shutdown` no cancela las tareas de consumer que sobreviven al timeout de 15 s**: si
  `asyncio.wait_for(asyncio.gather(*tasks), timeout=_SHUTDOWN_TASKS_TIMEOUT_S)` expira, se loguea
  `event_consumer_shutdown_timed_out` con el conteo de tareas vivas pero esas tareas siguen
  corriendo sin `cancel()` — intencional (cancelar un consumer a medio `XACK`/commit podría dejar
  estado a medias), pero no debería pasar nunca en producción (cada consumer responde a `stop` en
  ≤ `block_ms/1000 + 1s`); revisar si alguna vez se observa en logs reales.
- **`tests/support/raw_messages.py` hardcodea la retención en 90 días** (`_RETENTION_DAYS = 90`) en
  vez de leerla de `Settings.raw_message_retention_days`: si `LUKA_RAW_MESSAGE_RETENTION_DAYS`
  cambia de valor, este helper de test queda desincronizado con el comportamiento real.
- **`_BANK_VALUES` duplicado en 3 lugares**: `ingestion/infrastructure/orm.py`,
  `ledger/infrastructure/orm.py` y la migración `0003_raw_messages_review.py` (más
  `0002_ledger_core.py`) repiten la misma lista de bancos para sus `CHECK`/enums de columna. Forzado
  por R4 (un módulo no puede importar la lista de otro); hay que mantenerlas sincronizadas a mano al
  agregar un banco nuevo. Mitigado (no eliminado) por `tests/unit/test_enum_check_parity.py`, que
  falla si las cuatro copias dejan de coincidir.
- **El test del cron de requeue asume ejecución serial**: `tests/integration/ingestion/test_requeue_job.py`
  afirma `summary.requeued == 1` sobre una query global (todas las filas `pending` huérfanas, no filtradas por
  usuario/test), lo que depende de que ningún otro test dentro de la misma sesión de `pytest` haya
  dejado una fila `pending` sin limpiar (`db_clean` la protege hoy, pero un test futuro que no use
  `db_clean` podría romperlo sin aviso claro).

Riesgos abiertos del plan de Fase 2 (§4 del plan de implementación, ver detalle en §12.5 arriba):

- Sin outbox transaccional (mitigado por D8/D9/D10 + el cron de requeue).
- `llm_error` → revisión inmediata en vez de reintento del consumer (D11).
- Cap duro de 1 MB por request de ingesta.
- **Riesgo 7 — `client_hash` no se recomputa en el servidor**: el bucket de `posted_at` que entra en
  el hash lo calcula la app, así que la idempotencia de ingesta depende de que el cliente sea
  honesto. Aceptado: solo afecta los propios datos del usuario autenticado, y el dedupe de
  transacciones en `ledger` (spec 004 §3) es la garantía final (P2).
- **Riesgo 8 — presupuesto LLM comprobado antes / sumado después**: `used < limit` se verifica
  antes de llamar al LLM y los tokens se suman después de la respuesta, así que una sola llamada
  puede exceder el presupuesto mensual en hasta ~1K tokens. Aceptable para MVP.
- **Riesgo 11 — prefiltro monetario de `no_template` puede saltarse mensajes raros**: un mensaje
  bancario real sin ningún `$`/monto con separador de miles no llega al LLM (se descarta como
  `no_template` sin gastar tokens); son casos raros, pero requieren revisión con métricas reales de
  producción para confirmar que no se está perdiendo señal.

## 14. Verificación (corrida real, cierre de Fase 2 — 2026-09-21)

Todo corrido desde `backend/` contra la rama `CristianmMst/fase2-parsing`:

```sh
uv run ruff check .          # All checks passed!
uv run ruff format --check . # 330 files already formatted
uv run pyright                # 0 errors, 0 warnings, 0 informations
uv run lint-imports            # Contracts: 6 kept, 0 broken (R1, R2, R3a, R3b, R4, Kernel)
uv run pytest -q               # 780 passed, 1 warning (DeprecationWarning preexistente de arq) in 64.81s
uv run pytest tests/unit -m unit \
  --cov=luka.modules.ledger.domain --cov=luka.modules.identity.domain \
  --cov=luka.modules.parsing.domain --cov=luka.modules.ingestion.domain \
  --cov-fail-under=90
  # Required test coverage of 90% reached. Total coverage: 98.87% — 524 passed in 4.30s
uv run alembic upgrade head && uv run alembic check
  # No new upgrade operations detected.
grep -rn TBD docs/
  # solo docs/constitution.md:56 (la frase de la regla P8 en sí misma)
```

Recorrido en vivo (Docker Compose, perfil `app`; registro histórico, el perfil se retiró el 2026-09-23):

```sh
docker compose -f docker-compose.dev.yml --profile app up -d --build
curl -f localhost:8000/health/ready
# {"status":"ok","checks":{"database":"ok","redis":"ok"}}
```

Logs de arranque del worker (`docker logs backend-worker-1`):

```
Starting worker for 3 functions: ping, cron:purge_raw_message_bodies, cron:requeue_pending_raw_messages
worker_llm_status              enabled=False model=deepseek-v4-flash
llm_disabled_no_api_key
```

Recorrido curl de §11 contra la instancia levantada (`.env` ya existente). Se hizo el 2026-09-21, cuando
el backend aún tenía el verificador fake, eliminado el 2026-09-22:

1. **Login** → `POST /v1/auth/google` con `fake:demo11:demo11@example.com` → 200, `access_token`
   emitido.
2. **Crear cuenta** `(bancolombia, 1234)` → `POST /v1/accounts` → 200,
   `{"bank":"bancolombia","kind":"savings","last4":"1234","alias":"Ahorros"}`.
3. **Ingesta Bancolombia (compra_tdeb)** → `POST /v1/ingest/notifications` con
   `"Bancolombia: Compraste $176.824,00 en CARBON Y XILVESTRE T con tu T.Deb *1234, el 20/09/2026 a las 16:00"`
   → `{"accepted":1,"duplicates":0,"discarded":0}`.
4. **Poll `GET /v1/transactions`** → aparece en el primer intento (worker ya corriendo):
   `amount:"176824.00", direction:"debit", merchant:"CARBON Y XILVESTRE T", bank:"bancolombia",
   parsed_by:"rule:bancolombia:compra_tdeb:v1"`.
5. **`GET /v1/review`** → `{"items":[],"next_cursor":null}` (vacía, como se esperaba).
6. **`GET /v1/config/capture`** → 200, `version:1` + `banking_apps`/`messages_apps`/
   `sms_sender_patterns`/`email_senders` completos (7 apps bancarias, 6 bancos en `email_senders`).
7. **Ingesta de texto monetario sin plantilla** → `POST /v1/ingest/notifications` con
   `"Bancolombia: recibiste un giro internacional por $500.000,00 el 20/09/2026"` →
   `{"accepted":1,"duplicates":0,"discarded":0}`.
8. **`GET /v1/review`** → aparece con `"reason":"llm_disabled"`, `partial_extract:{}`, `text` con
   el cuerpo completo (`título\n\ntexto`).
9. **`POST /v1/review/{id}/convert`** con `{"amount":"500000.00","direction":"credit",
   "occurred_at":"2026-09-20T16:05:00-05:00","merchant":"Giro internacional"}` → **201**,
   `parsed_by:"manual"`, `sources:[{"channel":"notification","raw_message_id":"<id>", ...}]`.

Tras la verificación: `docker compose -f docker-compose.dev.yml stop api worker` (postgres/redis
quedaron corriendo).


## 15. Re-verificación (ola de fixes de cierre — 2026-09-22)

Tras la ola de fixes de la revisión final de rama (A1, A2, A3, A5, A10, B-I1..B-I3, B-M1, B-M2,
B-M4, B-M5), todo desde `backend/`:

```sh
uv run ruff check .          # All checks passed!
uv run ruff format --check . # 333 files already formatted
uv run pyright               # 0 errors, 0 warnings, 0 informations
uv run lint-imports          # Contracts: 6 kept, 0 broken
uv run pytest -q             # 794 passed, 1 warning (DeprecationWarning preexistente de arq) in 67.36s
uv run pytest tests/unit -m unit   --cov=luka.modules.ledger.domain --cov=luka.modules.identity.domain   --cov=luka.modules.parsing.domain --cov=luka.modules.ingestion.domain   --cov-fail-under=90
  # Required test coverage of 90% reached. Total coverage: 98.87% — 534 passed
uv run alembic upgrade head && uv run alembic check
  # 0003 -> 0004 (raw_messages_requeue_attempts); No new upgrade operations detected.
```

El recorrido en vivo de §14 no se repitió en esta ola (no cambió ningún endpoint); sí cambió el
esquema (migración `0004`, columna `raw_messages.requeue_attempts`) y el horario del cron de purga
(08:00 UTC = 03:00 en Colombia).

## 16. Gmail (Fase 3) — túnel de desarrollo y modo de prueba

Implementa spec 006 §2 (watch/sync), spec 005 §3/§4 (endpoints y webhook) y spec 004 §2.3
(`gmail_connections`). En Google Cloud (proyecto `luka-510204`) ya están habilitadas la Gmail
API y la Pub/Sub API, el topic `projects/luka-510204/topics/gmail-push` (con
`gmail-api-push@system.gserviceaccount.com` como Publisher), la cuenta de servicio
`gmail-push-invoker@luka-510204.iam.gserviceaccount.com` (sin llaves) y el scope
`gmail.readonly` en la pantalla de consentimiento, que está en modo de prueba.

### 16.1 Variables obligatorias

Las dos nuevas de Fase 3 (§10), ya en [`.env.example`](.env.example):

- `LUKA_GOOGLE_CLIENT_SECRET`: secreto del cliente OAuth web (consola de Google Cloud →
  Credenciales → el cliente web usado como `LUKA_GOOGLE_CLIENT_ID`). Genera uno nuevo si no lo
  tienes a mano.
- `LUKA_GMAIL_TOKEN_KEY`: 32 bytes aleatorios en base64, para AES-256-GCM. Se genera con:

  ```sh
  openssl rand -base64 32
  ```

### 16.2 Flujo de desarrollo local

El webhook `POST /v1/webhooks/gmail` lo llama Google (Pub/Sub), así que necesita una URL pública;
en desarrollo se usa un túnel de Cloudflare (`cloudflared`, sin cuenta):

```sh
just up       # Postgres + Redis
just dev      # API en :8000
just worker   # worker arq (sync_gmail, renew_gmail_watches)
just tunnel   # cloudflared tunnel --url http://localhost:8000
```

`just tunnel` imprime una URL `https://<random>.trycloudflare.com`. Con ella, en la consola
(Pub/Sub → Suscripciones → `gmail-push-dev` → Editar → URL del extremo) pega
`https://<random>.trycloudflare.com/v1/webhooks/gmail` y guarda. La suscripción
`gmail-push-dev` misma (nombre, OIDC con la cuenta `gmail-push-invoker`, audiencia
`luka-gmail-push`) se crea una sola vez en la consola (fuera de este repo); solo la URL del
extremo cambia en cada corrida de `just tunnel`, porque un "quick tunnel" no tiene dominio fijo —
la audiencia OIDC (`LUKA_GMAIL_PUSH_AUDIENCE`, default fijo `luka-gmail-push`) no cambia
con la URL, así que no hay que tocar nada del lado del backend.

Con la API, el worker y el túnel corriendo, `just app-run` lanza la app contra el backend local.

La captura es solo de INBOX (spec 006 §2): un correo del banco que un filtro de Gmail archiva o
mueve a otra etiqueta sin pasar por la bandeja de entrada no llega a luka. Para probar, el
correo tiene que quedar en la bandeja de entrada.

### 16.3 Modo de prueba de Google

Mientras la pantalla de consentimiento siga en modo de prueba (Google Auth Platform → Público en
prueba):

- Solo los usuarios de prueba declarados en la consola (hoy: `cristianmmst@gmail.com`) pueden
  conectar Gmail; cualquier otra cuenta ve un error de Google al autorizar.
- Google muestra el aviso "Google no verificó esta app" durante el consentimiento: es esperado, no
  un error (spec 010 §1); hay que continuar el flujo igual ("Avanzado" → "Ir a luka (no
  seguro)").
- Los grants de un scope restringido en modo de prueba **vencen a los 7 días**: pasado ese plazo,
  `sync_gmail`/`renew_gmail_watches` reciben `invalid_grant` de Google, la conexión pasa a
  `revoked` (spec 006 §2.1) y el usuario tiene que reconectar desde Ajustes (spec 008 §3.7). No es
  un bug del backend ni de la app.

### 16.4 Ver los logs de sincronización

Con el worker corriendo (§12.2), cada aviso push produce `gmail_sync_finished` (contadores
`fetched`/`accepted`/`duplicates`/`discarded`/`skipped`, nunca la cuenta ni contenido) y, por cada
mensaje, un `parsing_metric` (§12.4). El webhook en sí loguea `gmail_push_received` con
`jobs_enqueued`. Filtra la salida del worker, por ejemplo:

```sh
uv run arq luka.worker.WorkerSettings | grep -E "gmail_|parsing_metric"
```

### 16.5 Producción

En producción la pantalla de consentimiento pasa a público verificado (Verificación OAuth de
Google + auditoría CASA, spec 010 §1, roadmap F6.7) — sin el límite de usuarios de prueba ni el
vencimiento a 7 días — y la suscripción push apunta al dominio real de la API en vez de un túnel: desde el 2026-09-29
`gmail-push-dev` entrega a `https://luka.a360soft.tech/v1/webhooks/gmail` (backend/deploy/README.md).
Para volver a probar Gmail contra el backend local hay que apuntarla otra vez al túnel.
