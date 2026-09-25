# Nightfall — Console Leak CTF

| Campo | Valor |
|---|---|
| Categoría | Web / Virtual Host / LFI / SSH / SUID |
| Dificultad | **Media-alta** |
| Plataforma | Docker Compose |
| HTTP local | `9001` |
| SSH local | `2222` |
| Objetivos | Encontrar `user.txt` y `root.txt` |

## Descripción

Nightfall es un pequeño portal de archivos y operaciones. La aplicación
pública anuncia que el equipo se trasladó a otro virtual host, pero las
protecciones de la consola no están implementadas de forma consistente.

El recorrido esperado combina reconocimiento web, enumeración de usuarios,
análisis de respuestas HTTP, un LFI con validación de ruta defectuosa,
recuperación de una clave SSH y una escalada de privilegios mediante un
binario SUID.

Esta versión es una adaptación original para laboratorio local. Conserva las
ideas educativas del write-up de referencia, pero usa nombres, rutas,
credenciales, flags y código propios. No reproduce la máquina pública.

## Despliegue

Requisitos: Docker Engine y Docker Compose v2.

```bash
docker compose up --build -d
```

Página pública:

```text
http://127.0.0.1:9001
```

La consola usa el virtual host `console.nightfall.local`. Puedes
agregarlo a `/etc/hosts`:

```text
127.0.0.1 console.nightfall.local public.nightfall.local
```

También puedes trabajar sin modificar el archivo de hosts usando el header
`Host` en `curl`.

Para detener el laboratorio:

```bash
docker compose down
```

## Objetivos del estudiante

1. Descubrir el virtual host de la consola.
2. Obtener acceso al contenido de la consola sin autenticarse.
3. Leer archivos arbitrarios usando el módulo de registros.
4. Recuperar la clave SSH del usuario de operación.
5. Obtener la bandera de usuario y escalar hasta root.

El callback utilizado por la escalada apunta a
`host.docker.internal` y sólo se usa para comunicar el contenedor con
la máquina anfitriona local. No requiere exponer el laboratorio a Internet.

## Reglas

- Ejecuta el reto sólo sobre el contenedor local que tú levantaste.
- No uses la configuración para atacar otros equipos.
- No subas ni almacenes información real dentro del laboratorio.
- `SOLUTION.md` contiene las flags y la resolución completa; resérvalo
  para estudio o revisión docente.

## Pistas graduadas

<details>
<summary>Pista 1</summary>

Revisa el contenido de la página pública y prueba peticiones con distintos
headers `Host`.

</details>

<details>
<summary>Pista 2</summary>

En una autenticación, compara la respuesta para un usuario conocido con la de
un usuario inventado. Después revisa el cuerpo de las respuestas de redirección.

</details>

<details>
<summary>Pista 3</summary>

El módulo de registros exige que aparezca una carpeta concreta en el parámetro,
pero no necesariamente comprueba la ruta final después de normalizarla.

</details>

<details>
<summary>Pista 4</summary>

Una vez dentro por SSH, enumera SUID. El binario interesante puede enviar un
archivo como cuerpo de una petición HTTP.

</details>

## Estructura

```text
nightfall/
├── apache/
├── docker-compose.yml
├── Dockerfile
├── README.md
├── SOLUTION.md
├── src/
├── start-nightfall.sh
└── wordlists/
```
