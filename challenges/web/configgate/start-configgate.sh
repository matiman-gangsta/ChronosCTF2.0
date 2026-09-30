#!/bin/sh
set -eu

ROOT_FLAG="${GZCTF_FLAG:-${FLAG:-FLAG{configgate_path_hijack_91ad}}}"
unset GZCTF_FLAG || true
unset FLAG || true

printf '%s\n' "$ROOT_FLAG" > /root/root.txt
chmod 600 /root/root.txt
chown root:root /root/root.txt

# Auto-healing Watchdog contra interferencia o manipulación entre participantes
(
  while true; do
    sleep 5

    # 1. Asegurar persistencia e integridad de las banderas oficiales
    if [ ! -f /root/root.txt ] || [ "$(cat /root/root.txt 2>/dev/null)" != "$ROOT_FLAG" ]; then
      printf '%s\n' "$ROOT_FLAG" > /root/root.txt
      chmod 600 /root/root.txt
      chown root:root /root/root.txt
    fi

    if [ ! -f /home/analyst/user.txt ] || [ "$(cat /home/analyst/user.txt 2>/dev/null)" != 'FLAG{configgate_upload_6e21}' ]; then
      printf '%s\n' 'FLAG{configgate_upload_6e21}' > /home/analyst/user.txt
      chmod 644 /home/analyst/user.txt
      chown analyst:analyst /home/analyst/user.txt
    fi

    # 2. Asegurar permisos SUID en el binario del reto report-helper
    chmod 4755 /usr/local/bin/report-helper 2>/dev/null || true
    chown root:root /usr/local/bin/report-helper 2>/dev/null || true

    # 3. Limpieza de archivos subidos antiguos (más de 5 minutos) para evitar agotamiento de disco
    # y evitar que otros participantes reutilicen exploits preexistentes.
    find /var/www/html/attachments -type f ! -name 'index.html' -mmin +5 -delete 2>/dev/null || true
  done
) &

exec apache2-foreground
