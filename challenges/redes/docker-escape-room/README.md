# Docker Escape Room

**Categoría:** Redes  
**Dificultad:** Media  
**Puntos:** 300  

## Descripción

Tienes acceso SSH a un contenedor con un usuario sin privilegios elevados:

```bash
ssh ctfuser@<TARGET_IP> -p 2223
# Contraseña: ctf_docker_2024
```

Dentro del contenedor hay un socket de Docker expuesto en `/var/run/docker.sock` con permisos permisivos (`666`). Tu objetivo es usar ese socket para interactuar con el daemon de Docker y leer la bandera ubicada en `/root/flag.txt` fuera del contenedor.

## Despliegue y Arquitectura

Este reto está diseñado para ser completamente seguro para la infraestructura del torneo gracias al uso de **Docker-in-Docker (DinD)**:

```bash
docker compose up -d --build
```

Esto despliega:
1. `docker-host`: Contenedor simulador de host con Docker daemon independiente y `/root/flag.txt`. Incluye la imagen `alpine:latest` precargada para funcionamiento 100% offline.
2. `challenge`: Contenedor con SSH (puerto `2223`) donde inicia sesión el jugador.

## Validación Automática

```bash
chmod +x solution/solve.sh
./solution/solve.sh localhost 2223
```

Requiere tener instalado `sshpass` en la máquina que ejecute la prueba.

## Formato de Bandera

`CHRONOS{...}`
