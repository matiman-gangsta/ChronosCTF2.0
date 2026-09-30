#!/bin/sh
set -e

if [ -n "${GZCTF_FLAG:-}" ]; then
    echo "$GZCTF_FLAG" > /app/flag.txt
elif [ -n "${FLAG:-}" ]; then
    echo "$FLAG" > /app/flag.txt
fi

chmod 444 /app/flag.txt
unset GZCTF_FLAG || true
unset FLAG || true

exec gunicorn --bind 0.0.0.0:${PORT:-5000} --workers 2 --threads 4 app:app
