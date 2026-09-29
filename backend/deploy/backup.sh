#!/usr/bin/env bash
# Respaldo diario de Postgres en el VPS (backend/deploy/README.md). Guarda un
# volcado `pg_dump -Fc` en ~/apps/finanzia/backups y borra los de mas de
# RETENTION_DAYS. Cron del usuario del despliegue (`crontab -e`):
#
#   15 3 * * * $HOME/apps/finanzia/backup.sh >> $HOME/apps/finanzia/backups/backup.log 2>&1
#
# Queda en el mismo disco: copiarlo cifrado fuera del VPS es F6.2.
set -euo pipefail

cd "$(dirname "$0")"
RETENTION_DAYS="${RETENTION_DAYS:-14}"
mkdir -p backups
chmod 750 backups

stamp="$(date -u +%Y%m%dT%H%M%SZ)"
target="backups/finanzia-${stamp}.dump"

docker compose exec -T postgres pg_dump -U finanzia -d finanzia -Fc > "${target}.tmp"
mv "${target}.tmp" "$target"
chmod 600 "$target"

find backups -name 'finanzia-*.dump' -mtime +"$RETENTION_DAYS" -delete
echo "$(date -u +%FT%TZ) respaldo ${target} ($(du -h "$target" | cut -f1))"
