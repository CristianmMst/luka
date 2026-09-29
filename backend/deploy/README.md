# Despliegue del backend en un VPS (F6.1)

La API, el worker arq, Postgres 16, Redis 7 y Caddy corren con Docker Compose en un VPS (spec 003 §5, spec 009 §6). Cada push a `main` que toca `backend/` despliega solo, con el workflow `.github/workflows/deploy-backend.yml`.

| Archivo | Qué es |
|---|---|
| `../Dockerfile` | Imagen multietapa: el builder instala con `uv sync --frozen --no-dev`; el runtime solo trae el venv, `alembic.ini` y las migraciones, y corre como el usuario `app` (uid 10001). API, worker y migraciones usan la misma imagen. |
| `compose.yml` | El stack de producción. |
| `Caddyfile` | Proxy con HTTPS automático (Let's Encrypt) y cabeceras de seguridad, sin access log (P1). |
| `.env.example` | Las variables obligatorias del `.env` del servidor. |
| `bootstrap.sh` | Prepara un VPS nuevo: Docker, usuario `deploy`, SSH solo con llave, firewall, fail2ban y actualizaciones automáticas. |
| `backup.sh` | `pg_dump` diario con retención de 14 días. |

## Cómo queda el stack

- **Expuesto:** solo Caddy, en 80 y 443 (TCP y UDP para HTTP/3). El 80 redirige a HTTPS.
- **Red `data` interna:** Postgres y Redis no publican puertos ni tienen salida a internet. Solo la API, el worker y las migraciones los ven.
- **Contenedores de la app:** filesystem de solo lectura (con `/tmp` en tmpfs), `cap_drop: ALL`, `no-new-privileges` y usuario sin privilegios. La API corre 2 procesos (`WEB_CONCURRENCY`); el rate limit vive en Redis y lo comparten.
- **Redis:** guarda con AOF (`appendfsync everysec`). Es el bus de eventos y las colas de arq, y así no pierde eventos si se reinicia.
- **Healthchecks:** la API responde en `/health`, el worker se revisa con `arq --check` y Postgres y Redis tienen el suyo. Caddy espera a que la API esté sana.
- **Migraciones:** van en un servicio aparte (`migrate`, perfil `migrate`) que el despliegue corre antes de levantar la nueva versión.
- **Logs:** JSON (structlog, `FINANZIA_ENV=prod`), con rotación de 10 MB × 5 por contenedor.

## El workflow de despliegue

1. **`gate`:** `pip-audit --strict` sobre las dependencias de producción (exportadas de `uv.lock` con hashes) y gitleaks sobre el historial. Una vulnerabilidad conocida o un secreto frenan el despliegue (constitución P1, spec 009 §8).
2. **`build`:** construye la imagen con caché de GitHub Actions y la publica en `ghcr.io/cristianmmst/finanzia-backend` con el tag `sha-<commit>` y `latest`. Trae SBOM y atestación de procedencia.
3. **`deploy`** (entorno `production`):
   - Copia `compose.yml`, `Caddyfile` y `backup.sh` por SSH, verificando la huella del host.
   - Deja en `.env` la imagen fijada por **digest**.
   - Hace el pull, corre las migraciones y levanta el stack con `--wait`: si algo no queda sano, el job falla.
   - El token de GHCR solo vale durante el job y se borra del VPS al terminar.

Lint y tests ya no corren en GitHub: se corren en local antes de subir (`just lint`, `just test`, `just app-ci`).

## Primera vez

### 1. VPS y dominio

1. Crea un VPS con Ubuntu 24.04 o Debian 12. Con 2 GB de RAM alcanza para empezar. Activa el disco cifrado si el proveedor lo ofrece (spec 009 §6).
2. Crea un registro DNS `A` (y `AAAA` si hay IPv6), por ejemplo `api.tudominio.com`, que apunte a la IP del VPS.

### 2. Llave de despliegue y bootstrap

En tu máquina, crea una llave solo para GitHub Actions:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/finanzia_deploy -C finanzia-deploy -N ""
```

Copia `bootstrap.sh` al VPS y córrelo como root con la llave pública:

```bash
scp backend/deploy/bootstrap.sh root@<IP>:/root/
ssh root@<IP> "DEPLOY_PUBKEY='$(cat ~/.ssh/finanzia_deploy.pub)' bash /root/bootstrap.sh"
```

Deja SSH solo con llave. Antes de cerrar la sesión, comprueba que tu propia llave de root sigue entrando.

### 3. `.env` del servidor

```bash
ssh -i ~/.ssh/finanzia_deploy deploy@<IP>
cd ~/finanzia && nano .env    # contenido de backend/deploy/.env.example
chmod 600 .env
```

- `POSTGRES_PASSWORD`: `openssl rand -hex 32`.
- `FINANZIA_JWT_SECRET`: `openssl rand -base64 48`.
- `FINANZIA_GMAIL_TOKEN_KEY`: `openssl rand -base64 32`. Guárdala también fuera del VPS: sin ella hay que reconectar Gmail de todos los usuarios.
- `FINANZIA_GOOGLE_CLIENT_SECRET`: el secreto del cliente OAuth web de `finanzia-509500`.

Los secretos de la app viven solo aquí, nunca en GitHub.

### 4. GitHub

En el repo, ve a **Settings → Environments → New environment** y crea `production` con estos secretos:

| Secreto | Valor |
|---|---|
| `VPS_HOST` | IP o nombre del VPS |
| `VPS_USER` | `deploy` |
| `VPS_SSH_KEY` | Contenido de `~/.ssh/finanzia_deploy` (la llave privada) |
| `VPS_KNOWN_HOSTS` | Salida de `ssh-keyscan -t ed25519 <IP>` (revisa que la huella coincida con la del VPS) |

Con `gh` desde la terminal:

```bash
gh secret set VPS_SSH_KEY --env production < ~/.ssh/finanzia_deploy
ssh-keyscan -t ed25519 <IP> | gh secret set VPS_KNOWN_HOSTS --env production
gh secret set VPS_HOST --env production --body "<IP>"
gh secret set VPS_USER --env production --body deploy
```

Luego corre el workflow a mano (**Actions → Deploy backend → Run workflow**) o sube un cambio en `backend/`. Si el repo es privado, la imagen de GHCR también lo es: el VPS la baja con el token del job.

### 5. Después del primer despliegue

- Comprueba `https://<DOMAIN>/health/ready`: debe responder `{"status":"ok",...}`.
- En Google Cloud (`finanzia-509500`), cambia la URL del extremo de la suscripción push `gmail-push-dev` por `https://<DOMAIN>/v1/webhooks/gmail`. Ya no depende de `just tunnel`.
- Compila la app con `--dart-define=API_BASE_URL=https://<DOMAIN>`. En Codemagic, pon ese valor en el grupo `finanzia` (app/README.md).
- Programa el respaldo con `crontab -e` como `deploy`, usando la línea que trae `backup.sh`.

## Operación

Todo se corre como `deploy` en `~/finanzia`:

```bash
docker compose ps                                   # estado y salud
docker compose logs -f --tail=100 api worker        # logs (JSON)
docker compose run --rm migrate                     # migraciones a mano
docker compose run --rm api python -m finanzia.tools.reparse --since 2026-09-01
docker compose run --rm api python -m finanzia.tools.mark_self_transfers
docker compose restart worker
```

**Volver a una versión anterior.** Cambia `FINANZIA_IMAGE` en `.env` por `ghcr.io/cristianmmst/finanzia-backend:sha-<commit>` y corre `docker compose up -d --wait`. Las migraciones no se revierten solas, así que revisa si la versión vieja las soporta.

**Restaurar un respaldo:**

```bash
docker compose stop api worker
docker compose exec -T postgres pg_restore -U finanzia -d finanzia --clean --if-exists < backups/finanzia-<fecha>.dump
docker compose start api worker
```

**Pendiente (F6.2):** copiar los respaldos cifrados fuera del VPS y documentar una prueba de restauración.
