#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Iniciando servicio Docker Escape Room (ChronosCTF) ==="
docker compose down -v 2>/dev/null || true
docker compose build
docker compose up -d

echo "=== Esperando disponibilidad del puerto SSH (2223) ==="
sleep 5
echo "Servicio activo en ssh ctfuser@localhost -p 2223 (pass: ctf_docker_2024)"
