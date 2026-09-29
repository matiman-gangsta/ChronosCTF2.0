#!/bin/bash
set -e

# Inyectar bandera dinámica de GZCTF o valor por defecto
if [ -n "$GZCTF_FLAG" ]; then
    FLAG_VALUE="$GZCTF_FLAG"
elif [ -n "$FLAG" ]; then
    FLAG_VALUE="$FLAG"
else
    FLAG_VALUE="CHRONOS{w4f_byp4ss_ifs_4nd_w1ldc4rds_8842}"
fi

echo "$FLAG_VALUE" > /flag
chmod 444 /flag

# Limpiar las variables de entorno para que el jugador deba leer /flag vía el bypass intencionado
unset GZCTF_FLAG
unset FLAG

# Ejecutar Gunicorn
exec gunicorn -w 2 -b 0.0.0.0:5000 --timeout 10 app:app
