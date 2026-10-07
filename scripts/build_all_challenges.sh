#!/usr/bin/env bash
set -e

cd /opt/chronos-repo
echo "=== Actualizando repositorio ==="
git pull origin main || true

echo "=== Compilando retos Web ==="
for d in challenges/web/*; do
  if [ -f "$d/Dockerfile" ] && [ "$(basename "$d")" != "_template" ]; then
    name="$(basename "$d")"
    clean_name="$(echo "$name" | tr '-' '_')"
    echo ">>> Compilando $name..."
    docker build -t "${name}:latest" -t "chronos_challenge_${clean_name}:latest" -t "ctf-challenge-${name}:latest" "$d"
  fi
done

echo "=== Compilando retos Redes ==="
if [ -d "challenges/redes/docker-escape-room" ]; then
  echo ">>> Compilando docker-escape-room..."
  docker build -t "docker-escape-room:latest" -t "chronos_challenge_docker_escape_room:latest" challenges/redes/docker-escape-room
  if [ -d "challenges/redes/docker-escape-room/docker-host" ]; then
    docker build -t "docker-escape-room-host:latest" challenges/redes/docker-escape-room/docker-host
  fi
fi

echo "=== Lista de imágenes Docker disponibles ==="
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
