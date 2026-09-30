# luka

App multiplataforma (Flutter) de control de gastos personales con **captura automática de transacciones** (Gmail, notificaciones bancarias, SMS, NFC) y **generación del reporte anual de renta colombiano** (cifras organizadas según el formulario 210 de la DIAN).

> **Estado**: Spec-Driven Development en marcha. El **backend** Fase 0 (fundaciones del repo/tooling/CI) y Fase 1 (`identity` + `ledger` + bus de eventos sobre Redis Streams) ya están mergeadas en `main`. La Fase 2 del backend (pipeline de captura y parsing — Gmail queda para Fase 3; solo Bancolombia con plantillas reales) también está en `main` — ver la guía completa en [`backend/README.md`](backend/README.md). La **app Flutter** tiene scaffold (F0.6) y login con Google (F1.9) — ver [`app/README.md`](app/README.md). Pendiente: F2.7 (bancos restantes, diferido) y las fases 3 en adelante (Gmail, motor fiscal, producción).

## Metodología

Este proyecto sigue **Spec-Driven Development (SDD)**: primero se escribe la especificación completa y verificable; el código se implementa después, spec por spec, y cada cambio de comportamiento futuro empieza actualizando el spec correspondiente.

## Índice de documentación

| Documento | Contenido |
|---|---|
| [`docs/constitution.md`](docs/constitution.md) | Principios innegociables del proyecto |
| [`docs/specs/001-overview`](docs/specs/001-overview/spec.md) | Visión, usuarios, alcance MVP, glosario |
| [`docs/specs/002-requirements`](docs/specs/002-requirements/spec.md) | Requisitos funcionales y no funcionales con criterios de aceptación |
| [`docs/specs/003-architecture`](docs/specs/003-architecture/spec.md) | Arquitectura: monolito modular + hexagonal, Flutter feature-first |
| [`docs/specs/004-data-model`](docs/specs/004-data-model/spec.md) | Modelo de datos PostgreSQL y caché local Drift |
| [`docs/specs/005-api`](docs/specs/005-api/spec.md) | Contrato REST, webhooks e ingesta |
| [`docs/specs/006-capture-parsing`](docs/specs/006-capture-parsing/spec.md) | Pipeline de captura y parsing (Gmail, notificaciones, SMS, NFC, LLM) |
| [`docs/specs/007-fiscal`](docs/specs/007-fiscal/spec.md) | Motor fiscal: formulario 210, UVT, cédulas |
| [`docs/specs/008-app-flutter`](docs/specs/008-app-flutter/spec.md) | App Flutter: features, pantallas, offline-first |
| [`docs/specs/009-security`](docs/specs/009-security/spec.md) | Seguridad: modelo de amenazas, auth, cifrado |
| [`docs/specs/010-compliance`](docs/specs/010-compliance/spec.md) | Compliance: Google CASA, Play Store, Ley 1581 |
| [`docs/roadmap/tasks.md`](docs/roadmap/tasks.md) | Plan de implementación por fases (a ejecutar tras aprobación) |

## Stack (decidido)

- **App**: Flutter (Android + iOS) · Riverpod 3 · Drift (offline-first) · dio · go_router · nfc_manager · notification_listener_service · google_sign_in
- **Backend**: Python 3.12+ · FastAPI · SQLAlchemy/Alembic · PostgreSQL · Redis (colas/eventos/rate-limit) · arq (workers)
- **LLM parsing**: DeepSeek V4 Flash (respaldo del parsing por reglas)
- **Infra**: VPS compartido (Docker Compose: API + workers + Postgres + Redis, detrás del nginx del servidor) · Google Cloud Pub/Sub (push de Gmail)
