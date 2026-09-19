# Recetas de desarrollo para finanzia. Ver backend/README.md para detalle.

set shell := ["bash", "-uc"]

# Levanta la infra de desarrollo (Postgres + Redis). docker-compose.yml llega en F0.4.
up:
	docker compose up -d

# Detiene la infra de desarrollo.
down:
	docker compose down

# Corre la API en modo desarrollo con recarga automatica. finanzia.main llega en Task 1.
dev:
	cd backend && uv run uvicorn finanzia.main:app --reload

# Corre el worker arq. finanzia.worker llega en Task 1.
worker:
	cd backend && uv run arq finanzia.worker.WorkerSettings

# Corre toda la suite de tests.
test:
	cd backend && uv run pytest -q

# Corre solo los tests marcados como unitarios.
test-unit:
	cd backend && uv run pytest -q -m unit

# Lint completo: estilo, formato, tipos y fronteras entre modulos.
lint:
	cd backend && uv run ruff check .
	cd backend && uv run ruff format --check .
	cd backend && uv run pyright
	cd backend && uv run lint-imports

# Aplica migraciones Alembic. backend/migrations se puebla en tasks posteriores.
migrate:
	cd backend && uv run alembic upgrade head

# Genera una nueva revision Alembic con el mensaje dado.
revision name:
	cd backend && uv run alembic revision --autogenerate -m "{{name}}"

# Pipeline de CI: lint + tests.
ci: lint test
