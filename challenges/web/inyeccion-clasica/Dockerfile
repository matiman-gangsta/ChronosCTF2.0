FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PORT=5000 \
    DATABASE_PATH=/app/data/users.db

WORKDIR /app

RUN useradd --create-home --uid 10001 ctf

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .
COPY templates ./templates
COPY static ./static
RUN mkdir -p /app/data && \
    chown -R root:root /app && \
    chown -R ctf:ctf /app/data && \
    chmod 755 /app && \
    chmod 770 /app/data && \
    chmod 444 /app/app.py

USER ctf
EXPOSE 5000

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} --workers 2 --threads 4 app:app"]
