# Roadmap de implementación

> **Estado**: Fase 0 backend (F0.1–F0.5) y Fase 1 backend (F1.1–F1.8) completadas el 2026-09-20 en la rama `CristianmMst/backend-architecture-setup` (mergeada a `main`). Fase 2 backend (F2.1–F2.6, parsing Bancolombia) completada el 2026-09-21 en la rama `CristianmMst/fase2-parsing`, pendiente de integración a `main`. Pendientes: F0.6, F1.9 (app Flutter), F2.7 (bancos restantes, diferido) y las fases 3 en adelante. Cada tarea referencia los specs que implementa; una tarea está "hecha" cuando sus criterios de aceptación pasan en CI.

Convención: `F<fase>.<n>` · deps = tareas previas requeridas.

## Fase 0 — Fundaciones del repositorio

| ID | Tarea | Specs | Deps | Estado |
|---|---|---|---|---|
| F0.1 | Estructura monorepo: `/app`, `/backend`, `.gitignore`, licencias | 003 | — | ✅ |
| F0.2 | Backend scaffold: uv + FastAPI + estructura modular/hexagonal vacía (shared + 6 módulos con carpetas domain/application/infrastructure) | 003 §2 | F0.1 | ✅ |
| F0.3 | Tooling backend: ruff, pyright, pytest, import-linter con las 4 reglas de dependencia | 003 §2.2 | F0.2 | ✅ |
| F0.4 | docker-compose dev: Postgres 16 + Redis 7; settings con pydantic-settings | 003 §5 | F0.2 | ✅ |
| F0.5 | CI GitHub Actions: lint + tests + import-linter + pip-audit + gitleaks | 009 §8, RNF-7 | F0.3 | ✅ |
| F0.6 | App scaffold: `flutter create`, estructura feature-first vacía, riverpod/drift/dio/go_router configurados, flutter analyze/test en CI | 003 §3, 008 §1 | F0.1 | pendiente |

## Fase 1 — Identity + Ledger básico (RF-1, RF-7 parcial)

| ID | Tarea | Specs | Deps | Estado |
|---|---|---|---|---|
| F1.1 | Migraciones Alembic: users, refresh_tokens | 004 §2.1–2.2 | F0.4 | ✅ |
| F1.2 | `identity`: verificación id_token Google + `POST /auth/google` | 005 §2, 009 §2.1 | F1.1 | ✅ |
| F1.3 | `identity`: JWT + refresh rotativo con familias + `/auth/refresh`, `/auth/logout`; tests de reuso | 009 §2.2 | F1.2 | ✅ |
| F1.4 | Rate limiting middleware (Redis) para `/auth/*` | 009 §4 | F1.3 | ✅ |
| F1.5 | Migraciones: linked_accounts, categories (+seed sistema con fiscal_tags), transactions, transaction_sources, merchant_rules | 004 | F1.1 | ✅ |
| F1.6 | `ledger`: dominio puro — dedupe_key + tests; matcher transferencias + tests (incl. ambigüedad y exclusiones) | 004 §3–4, RF-5/6 | F1.5 | ✅ |
| F1.7 | `ledger`: repos SQLAlchemy + API transacciones/categorías/cuentas (CRUD, filtros, paginación cursor, Idempotency-Key) | 005 §6–7 | F1.6 | ✅ |
| F1.8 | Bus de eventos sobre Redis Streams en `shared` + consumers idempotentes | 003 §2.3 | F0.4 | ✅ |
| F1.9 | App feature `auth`: Google Sign-In, gate de sesión, secure storage, interceptor dio con refresh | 008 §3.1, 009 §2 | F0.6, F1.3 | pendiente |

## Fase 2 — Pipeline de parsing (RF-2 parcial, RF-5, RF-8)

| ID | Tarea | Specs | Deps | Estado |
|---|---|---|---|---|
| F2.1 | Migraciones: raw_messages (+unique idempotencia), review_queue | 004 §2.7, 2.10 | F1.5 | ✅ |
| F2.2 | Workers arq + wiring de eventos RawMessageReceived→parsing→ledger | 003 §2.4 | F1.8 | ✅ |
| F2.3 | Motor de plantillas regex (YAML) + normalizadores de monto/fecha/comercio; plantillas Bancolombia + Nequi con fixtures reales anonimizados | 006 §4.1, 4.3 | F2.2 | ✅ solo Bancolombia; Nequi diferido a F2.7 (sin fixture real) |
| F2.4 | Adapter DeepSeek (`LlmParserPort`): JSON mode, validación Pydantic, reintento, presupuesto por usuario en Redis | 006 §4.2 | F2.2 | ✅ |
| F2.5 | Flujo dedupe end-to-end: ON CONFLICT + adjuntar fuente + test de doble procesamiento (AC-5.1/5.2) | 004 §3 | F2.3, F1.6 | ✅ |
| F2.6 | Review queue: endpoints convert/discard + partial_extract | 005 §7 | F2.1 | ✅ |
| F2.7 | Plantillas Davivienda, Daviplata, BBVA, Banco de Bogotá (con fixtures) | 006 §4.1 | F2.3 | diferido: sin fixtures reales (Nequi, Davivienda, Daviplata, BBVA, Banco de Bogotá) |

## Fase 3 — Gmail (RF-2 completo)

| ID | Tarea | Specs | Deps |
|---|---|---|---|
| F3.1 | Proyecto GCP: consent screen (scopes), credenciales OAuth, topic Pub/Sub + permiso a gmail-api-push, subscription push con OIDC | 006 §2, 010 §1 | — |
| F3.2 | Migración gmail_connections; cifrado AES-GCM de refresh tokens (`shared/crypto`) + tests | 004 §2.3, 009 §3 | F1.1 |
| F3.3 | `POST /gmail/connect` (canje de serverAuthCode), DELETE, status; creación de watch | 005 §3 | F3.2 |
| F3.4 | Webhook `/webhooks/gmail`: verificación OIDC + history.list + filtro remitentes + encolar; tests con payloads simulados | 005 §4, 006 §2 | F3.3, F2.2 |
| F3.5 | Cron renovación de watches + resync tras cursor inválido | 006 §2.1 | F3.4 |
| F3.6 | App: paso de onboarding Gmail con autorización incremental + estado en Ajustes | 008 §3.1 | F1.9, F3.3 |
| F3.7 | Job de purga de raw_messages a 90 días (✅ adelantado en F2, Task 10) | 004 §6 | F2.1 |

## Fase 4 — App completa (RF-3, RF-4, RF-9)

| ID | Tarea | Specs | Deps |
|---|---|---|---|
| F4.1 | Esquema Drift completo + SyncCoordinator (pull incremental + outbox push) + tests de conflicto | 004 §5, 005 §9, 008 §5 | F1.9 |
| F4.2 | Feature transactions: lista, filtros, detalle con fuentes, edición de categoría (+merchant_rule prompt), marcar transfer | 008 §3.3 | F4.1 |
| F4.3 | Feature capture Android: NotificationCaptureService (config remota de paquetes, filtros, outbox, batch a /ingest) — backend hecho en F2 (`POST /ingest/notifications`, `GET /config/capture`); falta la app | 006 §3, 005 §5 | F4.1, F2.5 |
| F4.4 | Onboarding completo (4 pasos) + detección de permiso revocado | 008 §3.1 | F3.6, F4.3 |
| F4.5 | Feature capture NFC: lectura/escritura de tags, deep link quick-add, formulario rápido offline | 006 §5, 008 §3.4 | F4.1 |
| F4.6 | Dashboard (insights endpoint + pantalla con gráficos) | 005 §8, 008 §3.2 | F4.2 |
| F4.7 | Feature review (pantalla + badge) | 008 §3.5 | F2.6, F4.1 |
| F4.8 | Ajustes: cuentas, categorías, privacidad (exportar/borrar), estado conexiones | 008 §3.7, RF-11 | F4.2 |

## Fase 5 — Motor fiscal (RF-10)

| ID | Tarea | Specs | Deps |
|---|---|---|---|
| F5.1 | Config co_2025.yaml con valores UVT/topes oficiales DIAN verificados + loader versionado | 007 §3 | — |
| F5.2 | `fiscal` dominio: agregación por cédulas, límites UVT, topes de obligación; los 6 casos de prueba obligatorios | 007 §4, §6 | F5.1, F1.6 |
| F5.3 | Endpoints reporte (JSON + Excel worker) + trazabilidad | 005 §8, 007 §5 | F5.2 |
| F5.4 | App: pantalla reporte de renta + datos manuales (dependientes/patrimonio) + export | 008 §3.6 | F5.3, F4.1 |

## Fase 6 — Producción y lanzamiento

| ID | Tarea | Specs | Deps |
|---|---|---|---|
| F6.1 | Compose de producción (API xN, workers, Caddy TLS, redes internas) + guía de despliegue VPS + hardening (SSH, firewall, unattended-upgrades) | 003 §5, 009 §6 | F0.4 |
| F6.2 | Backups cifrados automatizados + prueba de restauración documentada | 009 §3, RNF-4 | F6.1 |
| F6.3 | Observabilidad: logs estructurados sin PII (test CI), métricas de pipeline, alertas mínimas | 009 §5, 006 §6 | F6.1 |
| F6.4 | Borrado de cuenta end-to-end (evento UserDeleted + purga + verificación ≤72 h) y exportación de datos | RF-11, 004 §6 | F4.8 |
| F6.5 | Documentos legales: política de privacidad, T&C, web mínima con borrado de cuenta | 010 §5 | — |
| F6.6 | Play Console: Data Safety, declaración de acceso a notificaciones, listing; TestFlight/App Store review | 010 §2 | F6.5 |
| F6.7 | Gate de 80 conexiones Gmail + proceso de verificación OAuth + agendar CASA | 010 §1 | F6.5 |
| F6.8 | Pruebas E2E de aceptación (lista de spec 002 §Verificación) en dispositivo real | todos | F5.4, F4.* |

## Orden crítico

```
F0 → F1 → F2 → F3 → F5 (backend)
        └→ F4 (app, en paralelo con F3 desde F4.1)
F6 al final, con F6.5–F6.7 arrancando en paralelo desde Fase 4.
```
