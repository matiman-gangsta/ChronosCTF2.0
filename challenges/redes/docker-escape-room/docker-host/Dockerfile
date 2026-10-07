# "docker-host": simula el host que corre el daemon de Docker, usando
# Docker-in-Docker para aislar la escalada del jugador dentro de este
# contenedor y no dentro del host real de quien despliegue el reto.

# 1. Etapa auxiliar para precargar un rootfs de alpine de forma 100% offline
FROM alpine:latest AS bundle-alpine

# 2. Contenedor daemon Docker-in-Docker
FROM docker:24-dind

# Copiamos el rootfs para permitir importar alpine:latest sin conexion a internet
COPY --from=bundle-alpine / /opt/offline-images/alpine

# Bandera "del host", ubicada en /root como en un servidor real.
COPY flag.txt /root/flag.txt
RUN chmod 600 /root/flag.txt

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
