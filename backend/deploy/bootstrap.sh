#!/usr/bin/env bash
# Prepara un VPS nuevo (Ubuntu 24.04 o Debian 12) para finanzia (F6.1,
# spec 009 §6). Se corre UNA vez como root:
#
#   DEPLOY_PUBKEY="ssh-ed25519 AAAA... finanzia-deploy" bash bootstrap.sh
#
# Deja: Docker oficial con el plugin compose, el usuario `deploy` (entra solo
# con la llave dada), SSH solo con llave, firewall con 22/80/443, fail2ban,
# actualizaciones de seguridad automaticas y ~deploy/finanzia listo para el
# `.env`. Es idempotente: correrlo otra vez no rompe nada.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Correlo como root." >&2
  exit 1
fi
if [[ -z "${DEPLOY_PUBKEY:-}" ]]; then
  echo "Falta DEPLOY_PUBKEY: la llave publica con la que entra GitHub Actions." >&2
  exit 1
fi

export DEBIAN_FRONTEND=noninteractive
. /etc/os-release

echo "==> Paquetes base y actualizaciones"
apt-get update -q
apt-get upgrade -yq
apt-get install -yq ca-certificates curl gnupg ufw fail2ban unattended-upgrades

echo "==> Docker (repositorio oficial)"
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -q
apt-get install -yq docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Rotacion de logs y sin escalada de privilegios por defecto en todo contenedor.
cat > /etc/docker/daemon.json <<'EOF'
{
  "log-driver": "json-file",
  "log-opts": { "max-size": "10m", "max-file": "5" },
  "no-new-privileges": true,
  "live-restore": true
}
EOF
systemctl enable --now docker
systemctl restart docker

echo "==> Usuario deploy"
id deploy >/dev/null 2>&1 || useradd --create-home --shell /bin/bash deploy
# El grupo docker equivale a root en esta maquina: solo lo tiene deploy.
usermod -aG docker deploy
install -d -m 700 -o deploy -g deploy /home/deploy/.ssh
touch /home/deploy/.ssh/authorized_keys
grep -qxF "$DEPLOY_PUBKEY" /home/deploy/.ssh/authorized_keys \
  || echo "$DEPLOY_PUBKEY" >> /home/deploy/.ssh/authorized_keys
chown deploy:deploy /home/deploy/.ssh/authorized_keys
chmod 600 /home/deploy/.ssh/authorized_keys
install -d -m 750 -o deploy -g deploy /home/deploy/finanzia /home/deploy/finanzia/backups

echo "==> SSH solo con llave"
cat > /etc/ssh/sshd_config.d/10-finanzia.conf <<'EOF'
PasswordAuthentication no
KbdInteractiveAuthentication no
PermitRootLogin prohibit-password
X11Forwarding no
EOF
sshd -t
systemctl reload ssh 2>/dev/null || systemctl reload sshd

echo "==> Firewall: 22, 80 y 443"
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 443/udp
ufw --force enable

echo "==> fail2ban (jail de sshd) y actualizaciones automaticas"
cat > /etc/fail2ban/jail.d/sshd.local <<'EOF'
[sshd]
enabled = true
backend = systemd
EOF
systemctl enable --now fail2ban
systemctl restart fail2ban
cat > /etc/apt/apt.conf.d/20auto-upgrades <<'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

echo
echo "Listo. Sigue en backend/deploy/README.md: escribir /home/deploy/finanzia/.env"
echo "y agregar la huella del host a GitHub (ssh-keyscan)."
