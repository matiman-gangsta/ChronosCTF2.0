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

# 4. Preparación de directorios en /opt/gzctf
echo "[4/6] Configurando estructura de directorios en /opt/gzctf..."
mkdir -p /opt/gzctf/{data/postgres,files}

# 5. Generación de credenciales seguras, appsettings.json y docker-compose.yml para GZCTF
echo "[5/6] Desplegando archivo docker-compose.yml y appsettings.json para GZCTF..."
POSTGRES_PASSWORD=$(openssl rand -hex 16)
XOR_KEY=$(openssl rand -hex 24)
ADMIN_PASSWORD="Chronos$(openssl rand -hex 6)!2026"

# Obtener IP pública asignada a la VM para PublicEntry
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me || echo "localhost")

cat <<EOF > /opt/gzctf/appsettings.json
{
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "Database": "Host=db:5432;Database=gzctf;Username=postgres;Password=${POSTGRES_PASSWORD}"
  },
  "XorKey": "${XOR_KEY}",
  "ContainerProvider": {
    "Type": "Docker",
    "PortMappingType": "Default",
    "PublicEntry": "${PUBLIC_IP}",
    "DockerConfig": {
      "SwarmMode": false,
      "Uri": "unix:///var/run/docker.sock"
    }
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  }
}
EOF

cat <<EOF > /opt/gzctf/admin_credentials.txt
======================================================
Credenciales de Administrador Inicial - GZCTF 2026
======================================================
URL: http://${PUBLIC_IP}
Usuario inicial: admin
Contraseña inicial: ${ADMIN_PASSWORD}
Postgres Password: ${POSTGRES_PASSWORD}
======================================================
EOF
chmod 600 /opt/gzctf/admin_credentials.txt

cat <<EOF > /opt/gzctf/docker-compose.yml
services:
  gzctf:
    image: gztime/gzctf:latest
    container_name: chronos_gzctf
    restart: always
    environment:
      - GZCTF_ADMIN_PASSWORD=${ADMIN_PASSWORD}
    ports:
      - "80:8080"
    volumes:
      - /opt/gzctf/appsettings.json:/app/appsettings.json:ro
      - /opt/gzctf/files:/app/files
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - ctf_platform
    depends_on:
      db:
        condition: service_healthy
    deploy:
      resources:
        limits:
          cpus: '1.2'
          memory: 1536M

  db:
    image: postgres:16-alpine
    container_name: chronos_postgres
    restart: always
    environment:
      - POSTGRES_DB=gzctf
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
    volumes:
      - /opt/gzctf/data/postgres:/var/lib/postgresql/data
    networks:
      - ctf_platform
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d gzctf"]
      interval: 10s
      timeout: 5s
      retries: 5
    deploy:
      resources:
        limits:
          cpus: '0.6'
          memory: 768M

networks:
  ctf_platform:
    internal: false
EOF

chmod 600 /opt/gzctf/appsettings.json

# 6. Servicio systemd para autoarranque de la plataforma
echo "[6/6] Configurando servicio systemd gzctf.service..."
cat <<'EOF' > /etc/systemd/system/gzctf.service
[Unit]
Description=GZCTF Platform Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/gzctf
ExecStart=/usr/bin/docker compose up -d
ExecStop=/usr/bin/docker compose down

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable gzctf.service

# Iniciar la plataforma de inmediato
cd /opt/gzctf && docker compose up -d

echo "=== [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Bootstrap de GZCTF completado con éxito ==="
