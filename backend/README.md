# backend

Monolito modular hexagonal de finanzia (Python 3.12, FastAPI, arq). Ver [`docs/specs/003-architecture`](../docs/specs/003-architecture/spec.md).

## Setup (Windows, PowerShell o Git Bash)

Requiere [uv](https://docs.astral.sh/uv/) y Python 3.12.

```sh
cd backend
uv sync --all-groups
```

## Comandos

```sh
uv run ruff check .          # lint
uv run ruff format --check . # formato
uv run pyright               # tipos
uv run lint-imports           # fronteras entre modulos (import-linter)
uv run pytest -q              # tests
```

También disponibles como recetas de [`just`](../justfile) desde la raíz del repo: `just lint`, `just test`, `just ci`.

## Login local sin GCP (verificador fake)

Con `FINANZIA_GOOGLE_VERIFIER=fake` (y `FINANZIA_ENV` distinto de `prod`, que lo prohíbe), `POST /v1/auth/google` acepta tokens sintéticos con el formato `fake:<sub>:<email>[:unverified[:<nombre>]]` en vez de un `id_token` real de Google. Útil para probar el flujo de login en desarrollo sin credenciales de Google Cloud.

```sh
curl -X POST http://localhost:8000/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "fake:demo:demo@example.com"}'
```

La respuesta trae `access_token`, `refresh_token`, `expires_in` y `user`. El acceso se usa como `Authorization: Bearer <access_token>` en `GET /v1/me`.
