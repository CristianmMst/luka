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
