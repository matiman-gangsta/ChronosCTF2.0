# ==============================================================================
# Multi-Stage Dockerfile para Portal de Emergencia (ChronosCTF 2026)
# Cumple con politicas de seguridad: usuario no-root ctf (10001) y ejecucion WSGI
# ==============================================================================

# ------------------------------------------------------------------------------
# Etapa 1: Builder
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build

COPY src/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ------------------------------------------------------------------------------
# Etapa 2: Runner
# ------------------------------------------------------------------------------
FROM python:3.12-slim AS runner

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=8000 \
    FLAG="CHRONOS{h1dd3n_c0mm3nts_4nd_r0b0ts_txt_9182}"

WORKDIR /app

# Crear usuario y grupo sin privilegios
RUN groupadd -g 10001 ctf && \
    useradd -u 10001 -g ctf -m -d /app -s /bin/sh ctf

# Copiar dependencias desde la etapa builder
COPY --from=builder /install /usr/local

# Copiar codigo fuente del reto y asignar propiedad al usuario ctf
COPY --chown=ctf:ctf src/ /app/
RUN chown -R ctf:ctf /app

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health').read()" || exit 1

USER ctf

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "--threads", "4", "--timeout", "30", "app:app"]
