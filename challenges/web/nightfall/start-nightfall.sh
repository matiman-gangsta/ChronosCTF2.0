#!/bin/sh
set -eu

mkdir -p /run/sshd
chmod 755 /run/sshd
ssh-keygen -A >/dev/null 2>&1 || true
/usr/sbin/sshd

exec apache2-foreground
