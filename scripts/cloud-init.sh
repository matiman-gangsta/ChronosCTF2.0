#!/usr/bin/env bash
# ==============================================================================
# ChronosCTF 2026 - Cloud-Init Bootstrap Script for Ubuntu 24.04 LTS
# ==============================================================================
# Este script inicializa el nodo principal:
# 0. Configura un swapfile de 4GB para resiliencia de memoria (evita OOM en B2s).
# 1. Actualiza el sistema operativo y paquetes base.
# 2. Instala Docker Engine y el plugin Docker Compose oficial.
# 3. Configura daemon.json con límites de logs y optimizaciones de seguridad.
# 4. Estructura directorios para GZCTF, Caddy, Backups y Stack de Monitoreo.
# 5. Configura Prometheus + Grafana (auto-provisioned) + cAdvisor + Node Exporter.
# 6. Detecta FQDN de Azure y genera Caddyfile con HTTPS (Let's Encrypt) + subruta /grafana.
# 7. Despliega appsettings.json, admin_credentials.txt y docker-compose.yml completo.
# 8. Configura backups periódicos de PostgreSQL en /etc/cron.hourly.
# 9. Habilita servicio systemd gzctf.service y arranca la infraestructura.
# ==============================================================================

set -euo pipefail
IFS=$'\n\t'

exec > >(tee -a /var/log/cloud-init-ctf.log) 2>&1
echo "=== [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Iniciando Bootstrap de ChronosCTF 2026 ==="

export DEBIAN_FRONTEND=noninteractive

# 0. Configuración de Swapfile de 4GB (Colchón crítico para evitar OOM)
if [ ! -f /swapfile ]; then
    echo "[0/9] Creando archivo Swap de 4GB para resiliencia de memoria..."
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' > /etc/sysctl.d/99-swap.conf
    echo "Swapfile de 4GB configurado exitosamente."
fi

# 1. Actualización del sistema y dependencias esenciales
echo "[1/9] Actualizando repositorios del sistema e instalando herramientas base..."
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
    unzip \
    python3

# 2. Instalación de Docker Engine Oficial
echo "[2/9] Configurando repositorio oficial de Docker..."
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
echo "[3/9] Configurando Docker Daemon (/etc/docker/daemon.json)..."
cat <<'EOF' > /etc/docker/daemon.json
{
  "features": {
    "containerd-snapshotter": false
  },
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

# 4. Preparación de directorios para Plataforma y Monitoreo
echo "[4/9] Configurando estructura de directorios en /opt/gzctf..."
mkdir -p /opt/gzctf/data/{postgres,caddy_data,caddy_config,prometheus_data,grafana_data}
mkdir -p /opt/gzctf/{files,backups,monitoring/prometheus,monitoring/grafana/provisioning/datasources,monitoring/grafana/provisioning/dashboards/json}
mkdir -p /var/log/caddy

# Permisos requeridos para contenedores de Grafana (UID 472) y Prometheus (UID 65534)
chown -R 472:472 /opt/gzctf/data/grafana_data
chown -R 65534:65534 /opt/gzctf/data/prometheus_data

# 5. Aprovisionamiento de configuración de Prometheus y Grafana
echo "[5/9] Generando configuración de Prometheus y Grafana..."

cat <<'EOF' > /opt/gzctf/monitoring/prometheus/prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'node'
    static_configs:
      - targets: ['node-exporter:9100']

  - job_name: 'cadvisor'
    static_configs:
      - targets: ['cadvisor:8080']
EOF

cat <<'EOF' > /opt/gzctf/monitoring/grafana/provisioning/datasources/prometheus.yml
apiVersion: 1
datasources:
  - name: Prometheus
    type: prometheus
    uid: prometheus
    access: proxy
    url: http://prometheus:9090
    isDefault: true
    editable: false
EOF

cat <<'EOF' > /opt/gzctf/monitoring/grafana/provisioning/dashboards/dashboards.yml
apiVersion: 1
providers:
  - name: 'ChronosCTF'
    orgId: 1
    folder: 'Infraestructura CTF'
    type: file
    disableDeletion: false
    updateIntervalSeconds: 30
    allowUiUpdates: true
    options:
      path: /etc/grafana/provisioning/dashboards/json
EOF

mkdir -p /opt/gzctf/monitoring/grafana/provisioning/dashboards/json
cat <<'EOF' > /opt/gzctf/monitoring/grafana/provisioning/dashboards/json/ctf_overview.json
{
  "annotations": { "list": [{ "builtIn": 1, "datasource": { "type": "grafana", "uid": "-- Grafana --" }, "enable": true, "hide": true, "name": "Annotations & Alerts", "type": "dashboard" }] },
  "editable": true,
  "fiscalYearStartMonth": 0,
  "graphTooltip": 1,
  "id": null,
  "liveNow": false,
  "panels": [
    {
      "collapsed": false,
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 0 },
      "id": 100,
      "title": "📌 Métricas Globales del Host (VM Azure B2s / Servidor)",
      "type": "row"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "max": 100,
          "min": 0,
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }, { "color": "#EAB839", "value": 65 }, { "color": "red", "value": 85 }] },
          "unit": "percent"
        }
      },
      "gridPos": { "h": 5, "w": 4, "x": 0, "y": 1 },
      "id": 1,
      "options": { "orientation": "auto", "reduceOptions": { "calcs": ["lastNotNull"], "values": false }, "showThresholdLabels": false, "showThresholdMarkers": true },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "100 - (avg(rate(node_cpu_seconds_total{mode=\"idle\"}[2m])) * 100)", "instant": true, "range": false, "refId": "A" }],
      "title": "⚡ Uso de CPU Host",
      "type": "gauge"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "max": 100,
          "min": 0,
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }, { "color": "#EAB839", "value": 70 }, { "color": "red", "value": 88 }] },
          "unit": "percent"
        }
      },
      "gridPos": { "h": 5, "w": 4, "x": 4, "y": 1 },
      "id": 2,
      "options": { "orientation": "auto", "reduceOptions": { "calcs": ["lastNotNull"], "values": false }, "showThresholdLabels": false, "showThresholdMarkers": true },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "(1 - (node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)) * 100", "instant": true, "legendFormat": "RAM Usada", "refId": "A" }],
      "title": "🧠 Uso de Memoria RAM",
      "type": "gauge"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "max": 100,
          "min": 0,
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }, { "color": "#EAB839", "value": 25 }, { "color": "red", "value": 50 }] },
          "unit": "percent"
        }
      },
      "gridPos": { "h": 5, "w": 4, "x": 8, "y": 1 },
      "id": 3,
      "options": { "colorMode": "value", "graphMode": "area", "reduceOptions": { "calcs": ["lastNotNull"], "values": false } },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "(1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100", "instant": true, "legendFormat": "Swap", "refId": "A" }],
      "title": "💾 Uso de Swap (Colchón B2s)",
      "type": "stat"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "max": 100,
          "min": 0,
          "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }, { "color": "#EAB839", "value": 75 }, { "color": "red", "value": 90 }] },
          "unit": "percent"
        }
      },
      "gridPos": { "h": 5, "w": 4, "x": 12, "y": 1 },
      "id": 4,
      "options": { "orientation": "auto", "reduceOptions": { "calcs": ["lastNotNull"], "values": false }, "showThresholdLabels": false, "showThresholdMarkers": true },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "max(100 - ((node_filesystem_avail_bytes{fstype!~\"rootfs|tmpfs\"} * 100) / node_filesystem_size_bytes{fstype!~\"rootfs|tmpfs\"}))", "instant": true, "legendFormat": "Disco /", "refId": "A" }],
      "title": "💿 Espacio en Disco (30GB)",
      "type": "gauge"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": {
        "defaults": {
          "color": { "mode": "thresholds" },
          "thresholds": { "mode": "absolute", "steps": [{ "color": "blue", "value": null }, { "color": "green", "value": 5 }, { "color": "#EAB839", "value": 25 }, { "color": "red", "value": 45 }] },
          "unit": "short"
        }
      },
      "gridPos": { "h": 5, "w": 4, "x": 16, "y": 1 },
      "id": 5,
      "options": { "colorMode": "value", "graphMode": "none", "reduceOptions": { "calcs": ["lastNotNull"], "values": false } },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "count(count by (name) (container_last_seen{name!=\"\"}))", "instant": true, "legendFormat": "Contenedores", "refId": "A" }],
      "title": "🐳 Contenedores Activos",
      "type": "stat"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "thresholds" }, "thresholds": { "mode": "absolute", "steps": [{ "color": "green", "value": null }, { "color": "red", "value": 1 }] }, "unit": "s" } },
      "gridPos": { "h": 5, "w": 4, "x": 20, "y": 1 },
      "id": 6,
      "options": { "colorMode": "value", "graphMode": "none", "reduceOptions": { "calcs": ["lastNotNull"], "values": false } },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "time() - node_boot_time_seconds", "instant": true, "legendFormat": "Uptime", "refId": "A" }],
      "title": "⏱️ Tiempo Activo (Uptime)",
      "type": "stat"
    },
    {
      "collapsed": false,
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 6 },
      "id": 101,
      "title": "📈 Tendencias de Rendimiento del Servidor",
      "type": "row"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 20, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2 }, "max": 100, "min": 0, "unit": "percent" } },
      "gridPos": { "h": 8, "w": 12, "x": 0, "y": 7 },
      "id": 7,
      "options": { "legend": { "calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "100 - (avg by (instance) (rate(node_cpu_seconds_total{mode=\"idle\"}[1m])) * 100)", "legendFormat": "CPU Total", "refId": "A" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "avg by (instance) (rate(node_cpu_seconds_total{mode=\"user\"}[1m])) * 100", "legendFormat": "CPU Usuario", "refId": "B" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "avg by (instance) (rate(node_cpu_seconds_total{mode=\"system\"}[1m])) * 100", "legendFormat": "CPU Sistema / Kernel", "refId": "C" }
      ],
      "title": "📊 Histórico de Uso de CPU",
      "type": "timeseries"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 30, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2, "stacking": { "group": "A", "mode": "normal" } }, "unit": "bytes" } },
      "gridPos": { "h": 8, "w": 12, "x": 12, "y": 7 },
      "id": 8,
      "options": { "legend": { "calcs": ["lastNotNull", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes", "legendFormat": "Memoria Usada", "refId": "A" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "node_memory_Cached_bytes + node_memory_Buffers_bytes", "legendFormat": "Buffers & Caché", "refId": "B" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "node_memory_MemFree_bytes", "legendFormat": "Memoria Libre", "refId": "C" }
      ],
      "title": "🧠 Desglose de Memoria RAM",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 15 },
      "id": 102,
      "title": "🎯 Telemetría de Contenedores de Retos y Plataforma (cAdvisor)",
      "type": "row"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 15, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2 }, "unit": "bytes" } },
      "gridPos": { "h": 9, "w": 12, "x": 0, "y": 16 },
      "id": 9,
      "options": { "legend": { "calcs": ["lastNotNull", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "topk(8, container_memory_working_set_bytes{name!=\"\"})", "legendFormat": "{{image}}", "refId": "A" }],
      "title": "🏆 Top Contenedores por Consumo de RAM",
      "type": "timeseries"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 15, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2 }, "unit": "percent" } },
      "gridPos": { "h": 9, "w": 12, "x": 12, "y": 16 },
      "id": 10,
      "options": { "legend": { "calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [{ "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "topk(8, rate(container_cpu_usage_seconds_total{name!=\"\"}[1m]) * 100)", "legendFormat": "{{image}}", "refId": "A" }],
      "title": "🔥 Top Contenedores por Consumo de CPU (%)",
      "type": "timeseries"
    },
    {
      "collapsed": false,
      "gridPos": { "h": 1, "w": 24, "x": 0, "y": 25 },
      "id": 103,
      "title": "🌐 Tráfico de Red e I/O de Almacenamiento",
      "type": "row"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 15, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2 }, "unit": "binBps" } },
      "gridPos": { "h": 7, "w": 12, "x": 0, "y": 26 },
      "id": 11,
      "options": { "legend": { "calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "sum(rate(node_network_receive_bytes_total{device!~\"lo|docker.*|br.*|veth.*\"}[1m]))", "legendFormat": "Entrada (Inbound / Subida)", "refId": "A" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "sum(rate(node_network_transmit_bytes_total{device!~\"lo|docker.*|br.*|veth.*\"}[1m]))", "legendFormat": "Salida (Outbound / Egress)", "refId": "B" }
      ],
      "title": "📶 Tráfico de Red (Ancho de Banda / Egress)",
      "type": "timeseries"
    },
    {
      "datasource": { "type": "prometheus", "uid": "prometheus" },
      "fieldConfig": { "defaults": { "color": { "mode": "palette-classic" }, "custom": { "fillOpacity": 15, "gradientMode": "opacity", "lineInterpolation": "smooth", "lineWidth": 2 }, "unit": "iops" } },
      "gridPos": { "h": 7, "w": 12, "x": 12, "y": 26 },
      "id": 12,
      "options": { "legend": { "calcs": ["mean", "max"], "displayMode": "table", "placement": "bottom", "showLegend": true } },
      "targets": [
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "sum(rate(node_disk_reads_completed_total[1m]))", "legendFormat": "Lecturas Disco / seg", "refId": "A" },
        { "datasource": { "type": "prometheus", "uid": "prometheus" }, "editorMode": "code", "expr": "sum(rate(node_disk_writes_completed_total[1m]))", "legendFormat": "Escrituras Disco / seg", "refId": "B" }
      ],
      "title": "💾 Operaciones I/O de Disco (IOPS)",
      "type": "timeseries"
    }
  ],
  "refresh": "30s",
  "schemaVersion": 38,
  "tags": ["chronos", "ctf", "infrastructure", "telemetry"],
  "time": { "from": "now-30m", "to": "now" },
  "timepicker": { "refresh_intervals": ["10s", "30s", "1m", "5m"] },
  "timezone": "browser",
  "title": "🛡️ ChronosCTF 2026 - Operations & Telemetry",
  "uid": "chronos-ctf-ops",
  "version": 1
}
EOF


# 6. Detección de Dominio y FQDN para HTTPS automático
echo "[6/9] Detectando Dominio / FQDN de Azure para aprovisionamiento HTTPS..."
PUBLIC_IP=$(curl -s --connect-timeout 5 ifconfig.me || echo "localhost")

# Consultar metadatos de Azure para obtener la región y construir el FQDN esperado
AZURE_LOC=$(curl -s -H Metadata:true --connect-timeout 3 "http://169.254.169.254/metadata/instance/compute/location?api-version=2021-02-01&format=text" 2>/dev/null || echo "eastus2")
DNS_LABEL="chronosctf-2026"
EXPECTED_FQDN="${DNS_LABEL}.${AZURE_LOC}.cloudapp.azure.com"

SERVER_DOMAIN=""
PTR_FQDN=$(python3 -c "import socket; print(socket.gethostbyaddr('$PUBLIC_IP')[0])" 2>/dev/null || true)

if [ -n "$PTR_FQDN" ] && [ "$PTR_FQDN" != "$PUBLIC_IP" ]; then
    SERVER_DOMAIN="$PTR_FQDN"
elif [ -n "$EXPECTED_FQDN" ]; then
    RESOLVED_IP=$(python3 -c "import socket; print(socket.gethostbyname('$EXPECTED_FQDN'))" 2>/dev/null || true)
    if [ "$RESOLVED_IP" = "$PUBLIC_IP" ]; then
        SERVER_DOMAIN="$EXPECTED_FQDN"
    fi
fi

# Si aún está propagando DNS en Azure, asignar el FQDN esperado
if [ -z "$SERVER_DOMAIN" ] && [ "$PUBLIC_IP" != "localhost" ]; then
    SERVER_DOMAIN="$EXPECTED_FQDN"
fi

if [ -z "$SERVER_DOMAIN" ]; then
    SERVER_DOMAIN="localhost"
fi

ADMIN_EMAIL="ma.nazal@duocuc.cl"
echo "Dominio asignado para HTTPS: ${SERVER_DOMAIN}"

# Configurar Caddyfile para Reverse Proxy + HTTPS automático + ruta /grafana
cat <<EOF > /opt/gzctf/Caddyfile
{
    email ${ADMIN_EMAIL}
}

${SERVER_DOMAIN} {
    encode zstd gzip

    # Panel de Telemetría Grafana
    handle /grafana* {
        reverse_proxy grafana:3000
    }

    # Plataforma Oficial GZCTF
    handle {
        reverse_proxy gzctf:8080 {
            header_up X-Forwarded-Proto {scheme}
            header_up X-Real-IP {remote_host}
        }
    }
}
EOF

# 7. Comprobación y Restauración de Backup desde Azure Blob Storage
echo "[7/9] Verificando existencia de respaldo previo en Azure Blob Storage..."
STORAGE_ACCOUNT="stchronosctfprod"
BACKUP_CONTAINER="backups"
BACKUP_BLOB="gzctf_full_backup.tar.gz"

MSI_TOKEN=$(curl -s -H Metadata:true --connect-timeout 5 "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || true)

if [ -n "$MSI_TOKEN" ]; then
    BLOB_URL="https://${STORAGE_ACCOUNT}.blob.core.windows.net/${BACKUP_CONTAINER}/${BACKUP_BLOB}"
    HTTP_CODE=$(curl -s -o /tmp/downloaded_backup.tar.gz -w "%{http_code}" -H "Authorization: Bearer ${MSI_TOKEN}" -H "x-ms-version: 2020-10-02" "${BLOB_URL}" || true)
    if [ "$HTTP_CODE" = "200" ] && [ -s /tmp/downloaded_backup.tar.gz ]; then
        echo "[Restore] Descarga exitosa (${HTTP_CODE}). Restaurando estructura y base de datos en /opt..."
        tar -xzf /tmp/downloaded_backup.tar.gz -C /opt
        rm -f /tmp/downloaded_backup.tar.gz
        echo "[Restore] ¡Datos previos de GZCTF restaurados exitosamente desde Blob Storage!"
    fi
fi

# Generación de credenciales si no existen previamente tras la restauración
if [ ! -f /opt/gzctf/appsettings.json ]; then
    echo "[Config] No se detectó configuración previa. Generando credenciales seguras y appsettings.json inicial..."
    POSTGRES_PASSWORD=$(openssl rand -hex 16)
    XOR_KEY=$(openssl rand -hex 24)
    ADMIN_PASSWORD="Chronos$(openssl rand -hex 6)!2026"

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
Credenciales de Administrador Inicial - ChronosCTF 2026
======================================================
URL Plataforma (HTTPS): https://${SERVER_DOMAIN}
URL Monitoreo (Grafana): https://${SERVER_DOMAIN}/grafana
URL Alternativa (IP):   http://${PUBLIC_IP}

Usuario inicial: admin
Contraseña inicial: ${ADMIN_PASSWORD}
Postgres Password: ${POSTGRES_PASSWORD}
======================================================
EOF
    chmod 600 /opt/gzctf/admin_credentials.txt
else
    echo "[Config] Configuración previa encontrada en /opt/gzctf/appsettings.json. Conservando credenciales y base de datos existentes."
    if [ -f /opt/gzctf/admin_credentials.txt ]; then
        ADMIN_PASSWORD=$(grep -E "Contrase.*a inicial:" /opt/gzctf/admin_credentials.txt | awk '{print $NF}')
    fi
    if [ -z "${ADMIN_PASSWORD:-}" ]; then
        ADMIN_PASSWORD="Chronos$(openssl rand -hex 6)!2026"
    fi
fi



cat <<EOF > /opt/gzctf/docker-compose.yml
services:
  caddy:
    image: caddy:2-alpine
    container_name: chronos_caddy
    restart: always
    ports:
      - "80:80"
      - "443:443"
    environment:
      - SERVER_DOMAIN=${SERVER_DOMAIN}
      - ADMIN_EMAIL=${ADMIN_EMAIL}
    volumes:
      - /opt/gzctf/Caddyfile:/etc/caddy/Caddyfile:ro
      - /opt/gzctf/data/caddy_data:/data
      - /opt/gzctf/data/caddy_config:/config
      - /var/log/caddy:/var/log/caddy
    networks:
      - ctf_platform
    depends_on:
      - gzctf
    deploy:
      resources:
        limits:
          cpus: '0.4'
          memory: 128M

  gzctf:
    image: gztime/gzctf:latest
    container_name: chronos_gzctf
    restart: always
    environment:
      - GZCTF_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - ASPNETCORE_FORWARDEDHEADERS_ENABLED=true
    expose:
      - "8080"
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

  # ============================================================================
  # Stack de Monitoreo Optimizado (Grafana + Prometheus + cAdvisor + Node-Exporter)
  # ============================================================================
  grafana:
    image: grafana/grafana-oss:latest
    container_name: chronos_grafana
    restart: always
    environment:
      - GF_SECURITY_ADMIN_USER=admin
      - GF_SECURITY_ADMIN_PASSWORD=${ADMIN_PASSWORD}
      - GF_SERVER_ROOT_URL=https://${SERVER_DOMAIN}/grafana/
      - GF_SERVER_SERVE_FROM_SUB_PATH=true
      - GF_USERS_ALLOW_SIGN_UP=false
      - GF_ANALYTICS_REPORTING_ENABLED=false
      - GF_ANALYTICS_CHECK_FOR_UPDATES=false
    volumes:
      - /opt/gzctf/data/grafana_data:/var/lib/grafana
      - /opt/gzctf/monitoring/grafana/provisioning:/etc/grafana/provisioning:ro
    networks:
      - ctf_platform
    depends_on:
      - prometheus
    deploy:
      resources:
        limits:
          cpus: '0.4'
          memory: 384M

  prometheus:
    image: prom/prometheus:v2.51.0
    container_name: chronos_prometheus
    restart: always
    command:
      - '--config.file=/etc/prometheus/prometheus.yml'
      - '--storage.tsdb.path=/prometheus'
      - '--storage.tsdb.retention.time=24h'
      - '--storage.tsdb.retention.size=1GB'
      - '--storage.tsdb.wal-compression'
    volumes:
      - /opt/gzctf/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml:ro
      - /opt/gzctf/data/prometheus_data:/prometheus
    networks:
      - ctf_platform
    deploy:
      resources:
        limits:
          cpus: '0.3'
          memory: 384M

  node-exporter:
    image: prom/node-exporter:latest
    container_name: chronos_node_exporter
    restart: always
    command:
      - '--path.rootfs=/host'
    volumes:
      - '/:/host:ro,rslave'
    networks:
      - ctf_platform
    deploy:
      resources:
        limits:
          cpus: '0.1'
          memory: 32M

  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.49.1
    container_name: chronos_cadvisor
    restart: always
    volumes:
      - /:/rootfs:ro
      - /var/run:/var/run:ro
      - /sys:/sys:ro
      - /var/lib/docker/:/var/lib/docker:ro
      - /dev/disk/:/dev/disk:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - ctf_platform
    deploy:
      resources:
        limits:
          cpus: '0.2'
          memory: 80M

networks:
  ctf_platform:
    internal: false
EOF

chmod 600 /opt/gzctf/appsettings.json

# 8. Configuración de Backup automático periódico de PostgreSQL y Sincronización a Blob Storage
echo "[8/9] Configurando cronjob de respaldo de base de datos..."
cat <<'EOF' > /etc/cron.hourly/gzctf-backup
#!/bin/sh
BACKUP_DIR="/opt/gzctf/backups"
mkdir -p "$BACKUP_DIR"
docker exec chronos_postgres pg_dump -U postgres gzctf 2>/dev/null | gzip > "$BACKUP_DIR/gzctf_$(date +\%Y\%m\%d_\%H\%M).sql.gz" || true
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +2 -delete 2>/dev/null || true

# Sincronización periódica a Azure Blob Storage
MSI_TOKEN=$(curl -s -H Metadata:true --connect-timeout 4 "http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://storage.azure.com/" | python3 -c "import sys, json; print(json.load(sys.stdin).get('access_token', ''))" 2>/dev/null || true)
if [ -n "$MSI_TOKEN" ]; then
    cd /opt && tar -czf /tmp/gzctf_sync_backup.tar.gz gzctf 2>/dev/null || true
    if [ -f /tmp/gzctf_sync_backup.tar.gz ]; then
        curl -s -X PUT -H "x-ms-blob-type: BlockBlob" -H "Authorization: Bearer ${MSI_TOKEN}" -H "x-ms-version: 2020-10-02" --upload-file /tmp/gzctf_sync_backup.tar.gz "https://stchronosctfprod.blob.core.windows.net/backups/gzctf_full_backup.tar.gz" >/dev/null 2>&1 || true
        rm -f /tmp/gzctf_sync_backup.tar.gz
    fi
fi
EOF
chmod +x /etc/cron.hourly/gzctf-backup

# 9. Servicio systemd para autoarranque de la plataforma
echo "[9/9] Configurando servicio systemd gzctf.service..."
cat <<'EOF' > /etc/systemd/system/gzctf.service
[Unit]
Description=ChronosCTF Platform Service (GZCTF + Caddy HTTPS + Grafana)
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

# 10. Clonar repositorio y compilar imágenes Docker de retos locales
echo "[10/10] Descargando retos y compilando imágenes Docker locales..."
if [ ! -d /opt/chronos-repo ]; then
    git clone -b feat/IaC_Cloud https://github.com/matiman-gangsta/ChronosCTF2.0.git /opt/chronos-repo || git clone https://github.com/matiman-gangsta/ChronosCTF2.0.git /opt/chronos-repo || true
fi

if [ -d /opt/chronos-repo/challenges ]; then
    echo "Compilando retos Web locales..."
    for d in /opt/chronos-repo/challenges/web/*; do
        if [ -f "$d/Dockerfile" ] && [ "$(basename "$d")" != "_template" ]; then
            name="$(basename "$d")"
            clean_name="$(echo "$name" | tr '-' '_')"
            docker build -t "${name}:latest" -t "chronos_challenge_${clean_name}:latest" -t "ctf-challenge-${name}:latest" "$d" || true
        fi
    done
    if [ -d "/opt/chronos-repo/challenges/redes/docker-escape-room" ]; then
        docker build -t "docker-escape-room:latest" -t "chronos_challenge_docker_escape_room:latest" /opt/chronos-repo/challenges/redes/docker-escape-room || true
        if [ -d "/opt/chronos-repo/challenges/redes/docker-escape-room/docker-host" ]; then
            docker build -t "docker-escape-room-host:latest" /opt/chronos-repo/challenges/redes/docker-escape-room/docker-host || true
        fi
    fi
fi

echo "=== [$(date -u +"%Y-%m-%dT%H:%M:%SZ")] Bootstrap de ChronosCTF con HTTPS y Grafana completado con éxito ==="

