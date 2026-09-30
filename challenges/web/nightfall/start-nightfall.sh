#!/bin/sh
set -eu

ROOT_FLAG="${GZCTF_FLAG:-${FLAG:-FLAG{nightfall_ab_shadow_90c2}}}"
unset GZCTF_FLAG || true
unset FLAG || true

printf '%s\n' "$ROOT_FLAG" > /root/root.txt
chmod 600 /root/root.txt
chown root:root /root/root.txt

mkdir -p /run/sshd
chmod 755 /run/sshd
ssh-keygen -A >/dev/null 2>&1 || true
/usr/sbin/sshd

# Watchdog de autoreparación contra sabotaje o interferencia entre participantes
(
  while true; do
    sleep 5
    # 1. Asegurar contraseña y acceso de root
    echo 'root:nightfall42' | chpasswd 2>/dev/null || true

    # 2. Restaurar banderas oficiales si fueron borradas o alteradas
    if [ ! -f /root/root.txt ] || [ "$(cat /root/root.txt 2>/dev/null)" != "$ROOT_FLAG" ]; then
      printf '%s\n' "$ROOT_FLAG" > /root/root.txt
      chmod 600 /root/root.txt
      chown root:root /root/root.txt
    fi

    if [ ! -f /home/archivist/user.txt ] || [ "$(cat /home/archivist/user.txt 2>/dev/null)" != 'FLAG{nightfall_ssh_path_4b7a}' ]; then
      printf '%s\n' 'FLAG{nightfall_ssh_path_4b7a}' > /home/archivist/user.txt
      chmod 644 /home/archivist/user.txt
      chown archivist:archivist /home/archivist/user.txt
    fi

    # 3. Restaurar llaves y permisos SSH para archivist
    if [ ! -f /home/archivist/.ssh/authorized_keys ] || [ ! -f /home/archivist/.ssh/id_ed25519 ]; then
      cp /home/archivist/.ssh/id_ed25519.pub /home/archivist/.ssh/authorized_keys 2>/dev/null || true
      chmod 755 /home/archivist/.ssh
      chmod 644 /home/archivist/.ssh/id_ed25519
      chmod 600 /home/archivist/.ssh/authorized_keys
      chown -R archivist:archivist /home/archivist/.ssh
    fi

    # 4. Asegurar permisos SUID en ApacheBench (ab)
    chmod 4755 /usr/bin/ab 2>/dev/null || true
    chown root:root /usr/bin/ab 2>/dev/null || true

    # 5. Asegurar que sshd siga activo
    if ! pgrep -x sshd >/dev/null 2>&1; then
      /usr/sbin/sshd || true
    fi
  done
) &

exec apache2-foreground
