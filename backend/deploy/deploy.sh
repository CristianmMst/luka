#!/usr/bin/env bash
# Despliega una imagen en ~/apps/finanzia (backend/deploy/README.md). Lo
# corre el workflow por SSH despues de copiar compose.yml y este archivo;
# tambien sirve a mano:
#
#   ~/apps/finanzia/deploy.sh ghcr.io/cristianmmst/finanzia-backend@sha256:...
#
# Es un archivo y no un script por stdin a proposito: `docker compose run`
# lee stdin y se comia el resto del script (el primer despliegue migro y
# nunca levanto la API).
set -euo pipefail

image="${1:?uso: deploy.sh <imagen>}"
cd "$(dirname "$0")"

test -f .env || { echo "Falta $(pwd)/.env (backend/deploy/README.md)." >&2; exit 1; }

sed -i '/^FINANZIA_IMAGE=/d' .env
echo "FINANZIA_IMAGE=$image" >> .env

docker compose pull --quiet
docker compose run --rm -T migrate < /dev/null
docker compose up -d --remove-orphans --wait --wait-timeout 180 < /dev/null

# Sin esto un despliegue a medias podia terminar en verde.
for service in api worker postgres redis; do
  if ! docker compose ps --status running --services | grep -qx "$service"; then
    echo "El servicio $service no quedo corriendo." >&2
    docker compose ps >&2
    docker compose logs --tail=50 "$service" >&2 || true
    exit 1
  fi
done

docker image prune -f > /dev/null
docker compose ps
