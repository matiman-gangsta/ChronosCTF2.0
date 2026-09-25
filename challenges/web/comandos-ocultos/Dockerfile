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

# Inyectar la bandera oficial en la raíz del sistema
# Permisos 0444: Lectura para todos los usuarios, pero NINGÚN usuario puede modificarla ni borrarla
RUN echo "CHRONOS{w4f_byp4ss_ifs_4nd_w1ldc4rds_8842}" > /flag && \
    chown root:root /flag && \
    chmod 444 /flag

# Copiar código de la aplicación y asignar propiedad (solo lectura para ctf)
COPY src/ .
RUN chown -R root:root /app && \
    chmod 755 /app && \
    chmod 444 /app/*

# Ejecutar como usuario no-root obligatorio
USER ctf

EXPOSE 5000

# Usar Gunicorn WSGI en producción para concurrencia y resiliencia
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "--timeout", "10", "app:app"]
