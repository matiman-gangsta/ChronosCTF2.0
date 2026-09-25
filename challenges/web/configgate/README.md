# ConfigGate — Upload Misconfiguration CTF

| Campo | Valor |
|---|---|
| Categoría | Web / File Upload / Linux Privilege Escalation |
| Dificultad | **Media** |
| Plataforma | Docker Compose |
| Puerto local | `9000` |
| Objetivos | Encontrar `user.txt` y `root.txt` |

## Descripción

ConfigGate es un portal interno que recibe archivos de configuración. Una
validación incompleta y una configuración insegura del servidor podrían
permitir que un archivo subido se procese de una forma que no estaba prevista.

Después de obtener ejecución de comandos, todavía tendrás que investigar el
contenedor y encontrar una forma de leer la segunda bandera.

El reto está inspirado conceptualmente en una cadena clásica de laboratorio
web —subida de archivo, ejecución en el servidor y escalada—, pero el código,
las rutas, los nombres y la escalada fueron creados específicamente para este
entorno local. No reproduce la máquina pública original.

## Despliegue

Requisitos: Docker Engine y Docker Compose v2.

```bash
docker compose up --build -d
```

Abre:

```text
http://127.0.0.1:9000
```

Para detener y eliminar el contenedor:

```bash
docker compose down
```

Si el puerto `9000` ya está ocupado, cambia el lado izquierdo de
`docker-compose.yml`, por ejemplo `9001:80`, y usa ese puerto
en el navegador.

## Objetivos del estudiante

1. Identificar cómo funciona el módulo de transferencia.
2. Conseguir ejecución de comandos dentro del contenedor.
3. Leer la bandera de usuario.
4. Analizar permisos y obtener la bandera de administrador.

No se necesitan herramientas externas, conexión a Internet ni una cuenta en
Hack The Box. El laboratorio debe ejecutarse únicamente en una máquina local.

## Reglas del laboratorio

- Usa el reto sólo en el contenedor local que tú levantaste.
- No subas datos reales al portal.
- `SOLUTION.md` contiene la solución completa y las banderas; debe
  reservarse para estudio, revisión docente o cuando el ejercicio ya haya
  terminado.

## Estructura

```text
configgate/
├── apache/configgate.conf
├── docker-compose.yml
├── Dockerfile
├── privesc/report-helper.c
├── README.md
├── SOLUTION.md
└── src/
    ├── attachments/index.html
    ├── index.php
    └── transfer.php
```

## Pistas graduadas

<details>
<summary>Pista 1</summary>

No te quedes sólo con el nombre del archivo: observa qué ocurre después de la
subida y dónde queda disponible.

</details>

<details>
<summary>Pista 2</summary>

El filtro bloquea algunas extensiones conocidas, pero no implementa una lista
positiva de tipos permitidos.

</details>

<details>
<summary>Pista 3</summary>

Cuando tengas una shell, revisa binarios SUID y presta atención a programas que
ejecuten utilidades por nombre en lugar de usar una ruta absoluta.

</details>
