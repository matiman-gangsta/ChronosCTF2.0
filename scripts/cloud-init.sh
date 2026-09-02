#!/usr/bin/env bash
# ==============================================================================
# ChronosCTF 2026 - Cloud-Init Bootstrap Script for Ubuntu 24.04 LTS
# ==============================================================================
# Este script inicializa el nodo principal:
# 1. Actualiza el sistema operativo y paquetes base.
# 2. Instala Docker Engine y el plugin Docker Compose oficial.
# 3. Configura daemon.json con límites de logs y optimizaciones de seguridad.
# 4. Estructura el directorio /opt/ctfd para la plataforma y retos.
# 5. Despliega un docker-compose.yml base para CTFd + MariaDB + Redis.
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

exec > >(tee -a /var/log/cloud-init-ctf.log) 2>&1
echo "=== [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Iniciando Bootstrap de ChronosCTF 2026 ==="

export DEBIAN_FRONTEND=noninteractive

# 1. Actualización del sistema y dependencias esenciales
echo "[1/6] Actualizando repositorios del sistema e instalando herramientas base..."
apt-get update -y
apt-get upgrade -y
apt-get install -y --no-install-recommends \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git \
    htop \
    jq \
    ufw \
    fail2ban \
    unzip

# 2. Instalación de Docker Engine Oficial
echo "[2/6] Configurando repositorio oficial de Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

apt-get update -y
apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin

# 3. Configuración optimizada del daemon de Docker
echo "[3/6] Configurando Docker Daemon (/etc/docker/daemon.json)..."
cat <<'EOF' > /etc/docker/daemon.json
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  },
  "live-restore": true,
  "default-ulimits": {
    "nofile": {
      "Name": "nofile",
      "Hard": 65536,
      "Soft": 65536
    }
  },
  "icc": true
}
EOF

systemctl enable docker
systemctl restart docker

# Añadir usuarios del sistema al grupo docker
for u in azureuser ubuntu admin; do
  if id "$u" &>/dev/null; then
    usermod -aG docker "$u"
    echo "Usuario $u añadido al grupo docker."
  fi
done

# 4. Preparación de directorios en /opt/ctfd
echo "[4/6] Configurando estructura de directorios en /opt/ctfd..."
mkdir -p /opt/ctfd/{data/mysql,data/redis,uploads,logs,challenges,nginx}

# 5. Generación de credenciales seguras y docker-compose.yml para CTFd
echo "[5/6] Desplegando archivo docker-compose.yml para CTFd..."
MYSQL_PASSWORD=$(openssl rand -hex 16)
SECRET_KEY=$(openssl rand -hex 24)

cat <<EOF > /opt/ctfd/.env
SECRET_KEY=${SECRET_KEY}
MYSQL_DATABASE=ctfd
MYSQL_USER=ctfd
MYSQL_PASSWORD=${MYSQL_PASSWORD}
MYSQL_ROOT_PASSWORD=$(openssl rand -hex 16)
EOF

cat <<'EOF' > /opt/ctfd/docker-compose.yml
services:
  ctfd:
    image: ctfd/ctfd:3.7.5
    restart: always
    environment:
      - UPLOAD_FOLDER=/var/uploads
      - DATABASE_URL=mysql+pymysql://ctfd:${MYSQL_PASSWORD}@db/ctfd
      - REDIS_URL=redis://cache:6379
      - SECRET_KEY=${SECRET_KEY}
      - REVERSE_PROXY=true
      - WORKERS=2
    volumes:
      - /opt/ctfd/logs:/var/log/CTFd
      - /opt/ctfd/uploads:/var/uploads
    ports:
      - "80:8000"
    networks:
      - ctf_internal
    depends_on:
      db:
        condition: service_healthy
      cache:
        condition: service_started
    deploy:
      resources:
        limits:
          cpus: '1.2'
          memory: 1536M

  db:
    image: mariadb:10.11-focal
    restart: always
    environment:
      - MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}
      - MYSQL_USER=ctfd
      - MYSQL_PASSWORD=${MYSQL_PASSWORD}
      - MYSQL_DATABASE=ctfd
    volumes:
      - /opt/ctfd/data/mysql:/var/lib/mysql
    networks:
      - ctf_internal
    command: [mysqld, --character-set-server=utf8mb4, --collation-server=utf8mb4_unicode_ci, --wait_timeout=28800, --log-warnings=0]
    healthcheck:
      test: ["CMD", "mariadb-admin", "ping", "-h", "localhost", "-u", "ctfd", "-p${MYSQL_PASSWORD}"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '0.6'
          memory: 768M

  cache:
    image: redis:7-alpine
    restart: always
    volumes:
      - /opt/ctfd/data/redis:/data
    networks:
      - ctf_internal
    deploy:
      resources:
        limits:
          cpus: '0.2'
          memory: 256M

networks:
  ctf_internal:
    internal: false
EOF

chmod 600 /opt/ctfd/.env
chown -R 1001:1001 /opt/ctfd/logs /opt/ctfd/uploads

# 6. Servicio systemd para autoarranque de la plataforma
echo "[6/6] Configurando servicio systemd ctfd.service..."
cat <<'EOF' > /etc/systemd/system/ctfd.service
[Unit]
Description=CTFd Platform Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/ctfd
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable ctfd.service

# Iniciar la plataforma de inmediato
cd /opt/ctfd && docker compose up -d

echo "=== [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Bootstrap completado con éxito ==="
