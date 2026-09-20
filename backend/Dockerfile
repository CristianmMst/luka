# syntax=docker/dockerfile:1

FROM ghcr.io/astral-sh/uv:python3.12-bookworm-slim AS builder

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy

WORKDIR /app

# Capa de dependencias, cacheable mientras no cambien pyproject.toml/uv.lock.
COPY pyproject.toml uv.lock ./
RUN uv sync --frozen --no-dev --no-install-project

# Codigo fuente del proyecto. alembic.ini se sumara cuando exista (tarea de migraciones).
COPY pyproject.toml uv.lock README.md src migrations ./
RUN uv sync --frozen --no-dev

FROM python:3.12-slim-bookworm AS runtime

RUN useradd -u 10001 -m app

WORKDIR /app
COPY --from=builder --chown=app:app /app /app

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://localhost:8000/health', timeout=2)"]

CMD ["uvicorn", "finanzia.main:app", "--host", "0.0.0.0", "--port", "8000"]
