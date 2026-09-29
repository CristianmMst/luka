# Recetas de desarrollo para finanzia. Ver backend/README.md para detalle.

set shell := ["bash", "-uc"]
# En Windows, `bash` del PATH es el de WSL (no ve uv ni flutter); se usa Git Bash.
set windows-shell := ["C:/Program Files/Git/bin/bash.exe", "-uc"]

# Levanta la infra de desarrollo (Postgres + Redis).
up:
	docker compose -f backend/docker-compose.dev.yml up -d --wait

# Detiene la infra de desarrollo.
down:
	docker compose -f backend/docker-compose.dev.yml down

# Corre la API en modo desarrollo con recarga automatica.
dev:
	cd backend && uv run uvicorn finanzia.main:app --reload

# Corre el worker arq (bus de eventos Redis Streams, F1.8).
worker:
	cd backend && uv run arq finanzia.worker.WorkerSettings

# Reprocesa los mensajes fallidos con cuerpo y cierra su revision (spec 005 §7).
# Uso: `just reparse` o `just reparse --since 2026-09-01`. Requiere el worker en marcha.
reparse *args:
	cd backend && uv run python -m finanzia.tools.reparse {{args}}

# Marca como transferencia los envios/recibos ya capturados al propio titular
# (spec 004 §4.1). Uso: `just mark-self-transfers` o `--user <uuid>`.
mark-self-transfers *args:
	cd backend && uv run python -m finanzia.tools.mark_self_transfers {{args}}

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

# Aplica migraciones Alembic (0001 identity, 0002 ledger).
migrate:
	cd backend && uv run alembic upgrade head

# Genera una nueva revision Alembic con el mensaje dado.
revision name:
	cd backend && uv run alembic revision --autogenerate -m "{{name}}"

# Gate de cobertura de dominio (ledger/identity/parsing/ingestion .domain >= 90%).
coverage-domain:
	cd backend && uv run pytest tests/unit -m unit --cov=finanzia.modules.ledger.domain --cov=finanzia.modules.identity.domain --cov=finanzia.modules.parsing.domain --cov=finanzia.modules.ingestion.domain --cov-fail-under=90

# Pipeline de CI: lint + tests + cobertura de dominio.
ci: lint test coverage-domain

# Tunel de desarrollo para el webhook de Gmail (F3.4): expone localhost:8000 con
# una URL publica https://<random>.trycloudflare.com. Cada corrida genera una URL
# nueva porque es un "quick tunnel" sin cuenta de Cloudflare, asi que hay que
# actualizar el endpoint de la suscripcion push `gmail-push-dev` (Pub/Sub ->
# Suscripciones -> gmail-push-dev -> Editar -> URL del extremo) a
# "<url>/v1/webhooks/gmail" cada vez que se corre este comando. La audiencia OIDC
# (`gmail_push_audience`, default `finanzia-gmail-push`) no cambia, solo el host.
tunnel:
	cloudflared tunnel --url http://localhost:8000

# --- App Flutter (app/, spec 008) ---

# Regenera codigo (freezed, json_serializable, drift) y textos l10n.
app-gen:
	cd app && dart run build_runner build --delete-conflicting-outputs
	cd app && flutter gen-l10n

# Corre la app en el dispositivo USB; el tunel adb expone el backend local en su localhost:8000.
app-run:
	adb reverse tcp:8000 tcp:8000
	cd app && flutter run

# Tests de la app (sin goldens).
app-test:
	cd app && flutter test --coverage --exclude-tags golden
	cd app && dart run tool/coverage_gate.dart

# Formato + analisis estatico de la app.
app-lint:
	cd app && dart format --output=none --set-exit-if-changed lib test tool
	cd app && flutter analyze --fatal-infos --fatal-warnings

# Regenera los goldens visuales del login (revisar el diff de imagenes).
app-goldens:
	cd app && flutter test --tags golden --update-goldens

# Pipeline de CI de la app.
app-ci: app-lint app-test

# Tests JUnit del listener nativo de notificaciones (JDK 17-21; gradlew lo genera flutter build apk).
app-android-test:
	cd app/android && ./gradlew :app:testDebugUnitTest
