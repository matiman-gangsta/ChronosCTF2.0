#!/bin/sh
# Entrypoint del contenedor "docker-host" (simula el host que corre el
# daemon de Docker). Usa Docker-in-Docker (dind) para que la escalada del
# jugador quede contenida dentro de este contenedor y NO comprometa el
# host real de quien despliegue el reto.
set -e

# Arranca dockerd, exponiendo el socket estandar y una copia dentro del
# volumen compartido para que el contenedor "challenge" pueda alcanzarlo.
dockerd-entrypoint.sh \
    --host=unix:///var/run/docker.sock \
    --host=unix:///var/run/docker-shared/docker.sock \
    --storage-driver=vfs &
DOCKERD_PID=$!

# Espera a que el daemon dockerd este respondiendo
echo "[docker-host] Esperando inicializacion de dockerd..."
until docker info >/dev/null 2>&1; do
    sleep 1
done

# Inyectar bandera dinámica con GUID (GZCTF) o valor por defecto
if [ -n "${GZCTF_FLAG:-}" ]; then
    FLAG_VALUE="$GZCTF_FLAG"
elif [ -n "${FLAG:-}" ]; then
    FLAG_VALUE="$FLAG"
elif [ -f /root/flag.txt ] && [ -s /root/flag.txt ]; then
    FLAG_VALUE="$(cat /root/flag.txt)"
else
    FLAG_VALUE="CHRONOS{b5a96d18-38f2-4e02-9a3b-851725832a81}"
fi

echo "$FLAG_VALUE" > /root/flag.txt
chmod 600 /root/flag.txt
unset GZCTF_FLAG || true
unset FLAG || true

# Precargar imagen alpine:latest para que el reto funcione 100% offline
if [ -d /opt/offline-images/alpine ]; then
    echo "[docker-host] Importando imagen alpine:latest para operacion offline..."
    tar -C /opt/offline-images/alpine -c . | docker import - alpine:latest >/dev/null 2>&1 || true
    echo "[docker-host] Imagen alpine:latest precargada exitosamente."
fi

# Espera a que el socket compartido exista y luego relaja sus permisos.
# Esto simula la vulnerabilidad real del reto: un socket de Docker expuesto
# con permisos demasiado abiertos (666), alcanzable por un usuario sin privilegios
# dentro del contenedor SSH del jugador.
i=0
while [ "$i" -lt 60 ]; do
    if [ -S /var/run/docker-shared/docker.sock ]; then
        chmod 666 /var/run/docker-shared/docker.sock
        echo "[docker-host] Socket expuesto en /var/run/docker-shared/docker.sock (modo 666)"
        break
    fi
    i=$((i + 1))
    sleep 1
done

wait "$DOCKERD_PID"
