# ==============================================================================
# Multi-Stage Dockerfile para Reto Web (Python 3.11 Slim)
# ChronosCTF 2026 - Conforme a politicas de usuario no-root y seguridad
# ==============================================================================

# ------------------------------------------------------------------------------
# Etapa 1: Builder (Instalación y compilación de dependencias)
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS builder

WORKDIR /build

# Instalar dependencias de compilación si son requeridas
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc python3-dev && \
    rm -rf /var/lib/apt/lists/*

COPY src/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ------------------------------------------------------------------------------
# Etapa 2: Runner (Entorno de ejecución mínimo y sin privilegios)
# ------------------------------------------------------------------------------
FROM python:3.11-slim AS runner

# Configurar variables de entorno de Python
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    FLAG="CHRONOS{d3fault_fl4g_f0r_t3mplat3_ch4ll3ng3}"

WORKDIR /app

# Crear usuario y grupo sin privilegios (no-root)
RUN groupadd -g 1000 ctf && \
    useradd -u 1000 -g ctf -m -d /app -s /bin/sh ctf

# Copiar paquetes instalados desde la etapa builder
COPY --from=builder /install /usr/local

# Copiar código fuente y asignar propiedad al usuario ctf
COPY --chown=ctf:ctf src/ /app/

# Exponer el puerto de la aplicación
EXPOSE 8000

# Healthcheck para monitoreo automático de estado
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()" || exit 1

# Cambiar a usuario sin privilegios
USER ctf

# Iniciar servidor mediante Gunicorn (listo para producción)
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--timeout", "30", "app:app"]
