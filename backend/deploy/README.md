# Despliegue del backend en el VPS (F6.1)

La API, el worker arq, Postgres 16 y Redis 7 corren con Docker Compose en el VPS compartido (`srv1633607`), en `~/apps/finanzia`, junto a las otras apps (spec 003 §5, spec 009 §6). La entrada es el nginx del servidor (`~/apps/nginx`), con certificados de certbot. Cada push a `main` que toca `backend/` despliega solo, con `.github/workflows/deploy-backend.yml`.

| Archivo | Qué es |
|---|---|
| `../Dockerfile` | Imagen multietapa. El builder usa `uv sync --frozen --no-dev`; el runtime solo trae el venv, `alembic.ini` y las migraciones, y corre como `app` (uid 10001). API, worker y migraciones usan la misma imagen. |
| `compose.yml` | El stack de finanzia. No publica puertos. |
| `nginx-finanzia.conf` | El server block para `~/apps/nginx/conf.d/finanzia.conf`, calcado de `biologistica.conf`. |
| `.env.example` | Las variables obligatorias del `.env` del servidor. |
| `deploy.sh` | Lo que corre el workflow en el VPS: fija la imagen, migra, levanta con `--wait` y verifica que `api`, `worker`, `postgres` y `redis` queden corriendo. Sirve también a mano. |
| `backup.sh` | `pg_dump` diario con retención de 14 días. |

## Cómo queda

```
internet ─▶ nginx (80/443, ~/apps/nginx) ─red proxy─▶ finanzia-api:8000
                                                        │
                            worker ─red egress─▶ Gmail, Google, DeepSeek
                              │                         │
                              └──── red data (interna) ─┴─▶ postgres, redis
```

- **Entrada:** finanzia no publica puertos. La API entra a la red compartida `proxy` con el alias `finanzia-api`, igual que `biologistica-backend`. El nginx resuelve ese nombre en cada petición, así que arranca aunque finanzia esté caído.
- **Datos:** Postgres y Redis están en la red `data`, interna y sin salida a internet. Son propios de finanzia y no chocan con los de las otras apps.
- **Contenedores de la app:** filesystem de solo lectura (con `/tmp` en tmpfs), `cap_drop: ALL`, `no-new-privileges` y usuario sin privilegios. La API corre 2 procesos (`WEB_CONCURRENCY`) que comparten el rate limit en Redis.
- **Redis:** guarda con AOF (`appendfsync everysec`) para no perder eventos del bus ni jobs de arq.
- **Healthchecks:** `/health` en la API, `arq --check` en el worker, y los propios de Postgres y Redis.
- **Migraciones:** van en un servicio aparte (`migrate`, perfil `migrate`) que el despliegue corre antes de levantar la versión nueva.
- **Logs:** la app escribe JSON (structlog) con rotación de 10 MB × 5. El nginx no guarda access log de finanzia (P1: la ruta cruda puede llevar datos del usuario).

## El workflow

1. **`gate`:** `pip-audit --strict` sobre las dependencias de producción (de `uv.lock`, con hashes) y gitleaks. Una vulnerabilidad conocida o un secreto frenan el despliegue (constitución P1, spec 009 §8).
2. **`build`:** publica `ghcr.io/cristianmmst/finanzia-backend` con los tags `sha-<commit>` y `latest`, con SBOM y atestación de procedencia.
3. **`deploy`:** entra por SSH con los secretos `VPS_HOST`, `VPS_USER` y `VPS_SSH_KEY`. La huella del host se lee con `ssh-keyscan` en cada despliegue. Luego:
   1. Copia `compose.yml`, `deploy.sh` y `backup.sh` a `~/apps/finanzia`.
   2. Corre `deploy.sh` con la imagen fijada por **digest**: migra, levanta con `--wait` y falla si algún servicio no queda corriendo.

   El token de GHCR se borra del VPS al terminar. El workflow **no toca el nginx**: ese paso es manual y se hace una vez.

Lint y tests no corren en GitHub. Se corren en local antes de subir: `just lint`, `just test` y `just app-ci`.

## Primera vez

Todo en el VPS, con el usuario de `VPS_USER`, que debe poder usar `docker`.

### 1. DNS

Crea un registro `A` para `luka.a360soft.tech` apuntando a la IP del VPS. Comprueba que resuelve con `dig +short luka.a360soft.tech`.

### 2. `.env`

```bash
mkdir -p ~/apps/finanzia && cd ~/apps/finanzia
cat > .env <<EOF
POSTGRES_PASSWORD=$(openssl rand -hex 32)
FINANZIA_JWT_SECRET=$(openssl rand -base64 48)
FINANZIA_GOOGLE_CLIENT_ID=30065910946-hatnfnvkk8782gf8qgbii9qdlqf61jn4.apps.googleusercontent.com
FINANZIA_GOOGLE_CLIENT_SECRET=PEGA_AQUI_EL_SECRETO
FINANZIA_GMAIL_TOKEN_KEY=$(openssl rand -base64 32)
FINANZIA_IMAGE=ghcr.io/cristianmmst/finanzia-backend:latest
EOF
chmod 600 .env
nano .env
```

- **`FINANZIA_GOOGLE_CLIENT_SECRET`:** pega aquí el secreto del cliente OAuth web de `finanzia-509500`.
- **`FINANZIA_GMAIL_TOKEN_KEY`:** guarda una copia fuera del VPS. Sin ella hay que reconectar Gmail de todos los usuarios.

Los secretos de la app viven solo aquí, nunca en GitHub.

### 3. Certificado y nginx

Primero, el bloque HTTP para el challenge. Copia `nginx-finanzia.conf` (de este repo) a `~/apps/nginx/conf.d/finanzia.conf` y **comenta el segundo `server` (el de 443)**, porque el certificado aún no existe. Luego recarga:

```bash
docker exec nginx nginx -t && docker exec nginx nginx -s reload
```

Después, emite el certificado con el certbot del servidor. Usa la misma red y el mismo webroot que las otras apps:

```bash
cd ~/apps/certbot
docker compose run --rm --entrypoint certbot certbot certonly \
  --webroot -w /var/www/certbot \
  -d luka.a360soft.tech \
  --cert-name luka-a360soft-tech \
  --email <tu-correo> --agree-tos --no-eff-email
```

Por último, descomenta el bloque de 443 y recarga otra vez con el mismo `nginx -t && nginx -s reload`. El certbot del servidor renueva el certificado solo, y el nginx se recarga cada 6 h.

### 4. Primer despliegue

Sube a `main` (o corre **Actions → Deploy backend → Run workflow**). Cuando termine:

- `https://luka.a360soft.tech/health/ready` debe responder `{"status":"ok",...}`.
- En Google Cloud (`finanzia-509500`), cambia la URL del extremo de la suscripción push `gmail-push-dev` a `https://luka.a360soft.tech/v1/webhooks/gmail`.
- Compila la app con `--dart-define=API_BASE_URL=https://luka.a360soft.tech`. En Codemagic, pon ese valor en el grupo `finanzia`.
- Programa el respaldo con `crontab -e`, con la línea que trae `backup.sh`.

## Operación

Todo en `~/apps/finanzia`:

```bash
docker compose ps                                   # estado y salud
docker compose logs -f --tail=100 api worker        # logs (JSON)
docker compose run --rm migrate                     # migraciones a mano
docker compose run --rm api python -m finanzia.tools.reparse --since 2026-09-01
docker compose run --rm api python -m finanzia.tools.mark_self_transfers
docker compose restart worker
tail -f ~/apps/nginx/logs/finanzia-api-error.log    # errores del proxy
```

**Volver a una versión anterior:** `./deploy.sh ghcr.io/cristianmmst/finanzia-backend:sha-<commit>` (con `docker login ghcr.io` si la imagen es privada). Las migraciones no se revierten solas, así que revisa si la versión vieja las soporta.

**Restaurar un respaldo:**

```bash
docker compose stop api worker
docker compose exec -T postgres pg_restore -U finanzia -d finanzia --clean --if-exists < backups/finanzia-<fecha>.dump
docker compose start api worker
```

**Pendiente (F6.2):** copiar los respaldos cifrados fuera del VPS y documentar una prueba de restauración.
