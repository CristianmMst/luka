# syntax=docker/dockerfile:1.7
#
# Imagen de produccion del backend (backend/deploy/README.md). La API, el
# worker arq y las migraciones usan la misma imagen; cambia solo el comando.

ARG PYTHON_VERSION=3.12

# --- builder: resuelve dependencias e instala el proyecto en /app/.venv -----
# Misma imagen base que el runtime: el venv apunta al mismo interprete.
FROM python:${PYTHON_VERSION}-slim-bookworm AS builder

COPY --from=ghcr.io/astral-sh/uv:0.11.7 /uv /usr/local/bin/uv

ENV UV_COMPILE_BYTECODE=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=0 \
    UV_PROJECT_ENVIRONMENT=/app/.venv

WORKDIR /app

# Capa de dependencias: solo se rehace si cambian pyproject.toml o uv.lock.
RUN --mount=type=cache,target=/root/.cache/uv \
    --mount=type=bind,source=uv.lock,target=uv.lock \
    --mount=type=bind,source=pyproject.toml,target=pyproject.toml \
    uv sync --frozen --no-dev --no-install-project

# El proyecto se instala como paquete (no editable): el runtime no necesita src/.
COPY pyproject.toml uv.lock README.md ./
COPY src ./src
RUN --mount=type=cache,target=/root/.cache/uv \
    uv sync --frozen --no-dev --no-editable

# --- runtime: solo el venv, alembic y las migraciones ------------------------
FROM python:${PYTHON_VERSION}-slim-bookworm AS runtime

LABEL org.opencontainers.image.title="luka-backend" \
      org.opencontainers.image.description="API FastAPI y worker arq de luka" \
      org.opencontainers.image.source="https://github.com/CristianmMst/luka" \
      org.opencontainers.image.licenses="LicenseRef-Proprietary"

RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --no-create-home --shell /usr/sbin/nologin app

WORKDIR /app

# Todo queda de root y de solo lectura para el usuario `app`.
COPY --from=builder /app/.venv /app/.venv
COPY alembic.ini ./
COPY migrations ./migrations

ENV PATH=/app/.venv/bin:$PATH \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1

USER app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["python", "-c", "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"]

# uvicorn toma los procesos de WEB_CONCURRENCY (1 por defecto). El rate limit
# vive en Redis, asi que varios procesos comparten el conteo.
CMD ["uvicorn", "luka.main:app", "--host", "0.0.0.0", "--port", "8000", "--no-server-header", "--timeout-graceful-shutdown", "20"]
