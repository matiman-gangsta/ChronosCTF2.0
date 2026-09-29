# ==============================================================================
# ChronosCTF 2026 - Reto Web: Comandos Ocultos (PingTool Pro)
# ==============================================================================

# Etapa 1: Builder para instalar dependencias de Python
FROM python:3.11-alpine AS builder

WORKDIR /app
COPY src/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# Etapa 2: Runner final hardened
FROM python:3.11-alpine

# Utilidades de red requeridas para el reto (ping y bash)
RUN apk add --no-cache iputils bash

WORKDIR /app

# Copiar dependencias de Python compiladas
COPY --from=builder /install /usr/local

# Crear usuario y grupo sin privilegios según estándar ChronosCTF
RUN addgroup -g 1000 ctf && \
    adduser -u 1000 -G ctf -s /bin/bash -D ctf

# Preparar archivo /flag para permitir inyección dinámica en arranque
RUN touch /flag && \
    chown ctf:ctf /flag && \
    chmod 644 /flag

# Copiar código de la aplicación y asignar propiedad (solo lectura para ctf)
COPY src/ .
RUN chown -R root:root /app && \
    chmod 755 /app && \
    chmod 444 /app/*

# Copiar script de arranque para soporte de bandera dinámica (GZCTF)
COPY entrypoint.sh /entrypoint.sh
RUN chmod 755 /entrypoint.sh

# Ejecutar como usuario no-root obligatorio
USER ctf

EXPOSE 5000

# Usar entrypoint para inyección dinámica de flag y arranque con Gunicorn
ENTRYPOINT ["/entrypoint.sh"]
