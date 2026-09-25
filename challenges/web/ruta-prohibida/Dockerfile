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
RUN chown -R ctf:ctf /app && chmod 0444 /app/flag.txt

USER ctf
EXPOSE 5000

CMD ["sh", "-c", "gunicorn --bind 0.0.0.0:${PORT} --workers 2 --threads 4 app:app"]
