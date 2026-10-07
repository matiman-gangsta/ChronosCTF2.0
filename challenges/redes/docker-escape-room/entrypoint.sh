#!/bin/bash
# Entrypoint del contenedor "challenge" (al que se conecta el jugador por SSH).
set -e

mkdir -p /var/run/sshd

# Espera a que el socket de Docker expuesto por "docker-host" este
# disponible en el volumen compartido, y crea el enlace en la ruta
# convencional /var/run/docker.sock para que el jugador lo encuentre ahi,
# tal como se describe en el enunciado del reto.
i=0
while [ "$i" -lt 60 ]; do
    if [ -S /var/run/docker-shared/docker.sock ]; then
        ln -sf /var/run/docker-shared/docker.sock /var/run/docker.sock
        echo "[challenge] Socket de Docker enlazado en /var/run/docker.sock"
        break
    fi
    i=$((i + 1))
    sleep 1
done

exec /usr/sbin/sshd -D
