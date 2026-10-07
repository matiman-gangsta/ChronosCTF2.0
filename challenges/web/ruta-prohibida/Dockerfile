FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000

WORKDIR /app

RUN useradd --create-home --uid 10001 ctf

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py flag.txt ./
COPY templates ./templates
COPY static ./static
COPY archive ./archive
COPY entrypoint.sh /entrypoint.sh
RUN chown -R ctf:ctf /app && \
    chmod 755 /app && \
    chmod 444 /app/app.py && \
    chmod 644 /app/flag.txt && \
    chmod 755 /entrypoint.sh

USER ctf
EXPOSE 5000

ENTRYPOINT ["/entrypoint.sh"]
