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
#
# La salida va al log de GitHub Actions, que es PUBLICO (repo publico): este
# script nunca imprime `docker compose logs` ni valores del `.env`. Los logs
# se leen en el VPS.
set -euo pipefail

image="${1:?uso: deploy.sh <imagen>}"
cd "$(dirname "$0")"

test -f .env || { echo "Falta $(pwd)/.env (backend/deploy/README.md)." >&2; exit 1; }

sed -i '/^FINANZIA_IMAGE=/d' .env
echo "FINANZIA_IMAGE=$image" >> .env

docker compose pull --quiet

# El .env se valida con la imagen nueva antes de tocar nada. Settings oculta
# los valores en sus errores (hide_input_in_errors): sale el campo y el motivo.
if ! docker compose run --rm -T --no-deps api \
    python -c "from finanzia.shared.settings import get_settings; get_settings()" < /dev/null; then
  echo "El .env de $(pwd) no es valido: corrigelo y vuelve a desplegar." >&2
  exit 1
fi

docker compose run --rm -T migrate < /dev/null

if ! docker compose up -d --remove-orphans --wait --wait-timeout 180 < /dev/null; then
  docker compose ps >&2
  echo "Algun servicio no quedo sano: revisa 'docker compose logs <servicio>' en el VPS." >&2
  exit 1
fi

# Sin esto un despliegue a medias podia terminar en verde.
for service in api worker postgres redis; do
  if ! docker compose ps --status running --services | grep -qx "$service"; then
    docker compose ps >&2
    echo "El servicio $service no quedo corriendo: revisa 'docker compose logs $service' en el VPS." >&2
    exit 1
  fi
done

docker image prune -f > /dev/null
docker compose ps
