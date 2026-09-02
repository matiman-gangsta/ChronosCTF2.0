# ChronosCTF 2.0 - Reglas de Ingeniería y Arquitectura

Bienvenido al repositorio oficial de infraestructura y retos para el torneo **ChronosCTF 2026**.
Como equipo de ingeniería, operamos bajo restricciones presupuestarias y de seguridad estrictas. Todo colaborador (DevOps, SysAdmins, Challenge Authors) debe acatar las siguientes directivas.

---

## 1. Restricciones Presupuestarias y FinOps (Azure for Students - $100 USD)

El torneo cuenta con un presupuesto no ampliable de **100 USD** otorgado por suscripciones de *Azure for Students*. La regla de oro es **eficiencia máxima de costos**.

### 1.1. Recursos Estrictamente Prohibidos
Queda terminantemente prohibido aprovisionar o solicitar en Terraform cualquiera de los siguientes servicios PaaS/IaaS de alto costo:
- **AKS (Azure Kubernetes Service)**: Costo mínimo de nodos y plano de control desborda el presupuesto en días.
- **Azure SQL Database / Azure Database for MySQL/PostgreSQL**: Costo prohibitivo. Las bases de datos necesarias (MariaDB/Redis para CTFd) deben correr como contenedores Docker locales en la VM principal con volúmenes persistentes.
- **Azure Application Gateway / Azure Front Door**: Sustituido por Nginx Reverse Proxy con certificados TLS automáticos de Let's Encrypt (`certbot`) dentro del host.
- **Azure Firewall / NAT Gateway**: Costo horario base excesivo (~$30/mes solo el NAT Gateway). La salida a internet se realiza vía la IP pública estándar asignada a la NIC.
- **Azure Container Instances (ACI)** o **App Service Planes (Standard/Premium)**.
- **Discos Premium SSD (P-tier)** mayores a 32GB: Utilizar únicamente `StandardSSD_LRS` de 30GB.

### 1.2. Recursos Permitidos y Dimensionamiento
- **Cómputo**: Una máquina virtual `Standard_B2s` (2 vCPU, 4 GiB RAM) con créditos de ráfaga (burstable), o en caso de pico extremo de jugadores `Standard_B4ms` durante las 48 horas del torneo, apagándola o escalándola inmediatamente después.
- **Almacenamiento**: Disco de SO de 30GB `StandardSSD_LRS`.
- **Registro de Contenedores**: Azure Container Registry (ACR) en SKU **Basic** (~$5 USD/mes). Se deben purgar imágenes antiguas o tags huérfanos.
- **Redes**: Virtual Network con 1 subred para la plataforma y 1 subred para los retos, protegidas por un único Network Security Group (NSG).

---

## 2. Estándares de Seguridad y Empaquetado Docker

Para garantizar que un reto explotado no comprometa el host subyacente ni los retos vecinos, se exigen las siguientes políticas de contenedorización:

### 2.1. Usuario No-Root Obligatorio
- **NUNCA** ejecutar procesos como `root` dentro del contenedor.
- Crear un usuario y grupo sin privilegios (ej. `ctf:ctf` con UID/GID 1000 o mayor):
  ```dockerfile
  RUN groupadd -g 1000 ctf && \
      useradd -u 1000 -g ctf -m -s /bin/bash ctf
  USER ctf
  ```
- No otorgar permisos de `sudo` ni binarios SUID a menos que sea el objetivo intencionado de un reto de escalada local (y en tal caso, debidamente aislado).

### 2.2. Construcción Multi-Stage (Multi-Stage Builds)
- Separar la etapa de compilación (`builder`) de la etapa de ejecución (`runner`).
- La imagen final debe basarse en distribuciones mínimas: `alpine`, `distroless` o `slim` (ej. `python:3.11-slim`, `node:20-alpine`, `golang:1.22-alpine`).
- Evitar dejar herramientas de compilación (`gcc`, `make`), cabeceras de desarrollo (`*-dev`) o administradores de paquetes que faciliten la post-explotación al atacante.

### 2.3. Hardening y Confinamiento
- **Sistema de archivos de solo lectura**: Diseñar el contenedor para que soporte `read_only: true` en Docker Compose. Si la aplicación requiere escribir archivos temporales o de sesión, montar un volumen en memoria `tmpfs` en `/tmp` con tamaño restringido (ej. `tmpfs: /tmp:size=16M,exec`).
- **Límites de Recursos (cgroups)**: Todo reto debe declarar explícitamente límites de memoria y CPU en su definición de servicio para mitigar ataques de denegación de servicio (DoS) o forks bombs:
  ```yaml
  deploy:
    resources:
      limits:
        cpus: '0.50'
        memory: 128M
  ```
- **Capacidades del Kernel (Linux Capabilities)**: Dropear todas las capacidades y agregar únicamente las indispensables:
  ```yaml
  cap_drop:
    - ALL
  ```
- **Manejo de Flags**:
  - Las flags deben inyectarse mediante variables de entorno en runtime o montarse como archivos de solo lectura con permisos `0400` propiedad del usuario `root` o un usuario distinto al de la app si el reto involucra LFI / lectura arbitraria.
  - Formato oficial obligatorio: `CTF{...}` o `CHRONOS{...}`.

---

## 3. Guía de Buenas Prácticas para Autores de Retos

1. **Estructura Uniforme**: Cada reto debe residir en `challenges/<categoria>/<nombre-reto>/` y contener:
   - `Dockerfile`: Receta reproducible y multi-stage.
   - `challenge.yml`: Archivo de metadatos compatible con especificación CTFd.
   - `solution.md`: Writeup oficial detallado con la vulnerabilidad, análisis y pasos de explotación.
   - `solution/` (opcional): Script de solución automatizado (solve script en Python / pwntools).
   - `src/`: Código fuente del desafío.

2. **Determinismo y Resiliencia**:
   - El reto debe poder reiniciar su estado automáticamente en caso de fallo (usar `restart: on-failure`).
   - Evitar estados globales persistentes que permitan a un participante "romper" el reto para los demás jugadores (DoS involuntario).
   - Si el reto modifica archivos en runtime, usar instancias efímeras o scripts de limpieza periódicos en `/tmp`.

3. **Confidencialidad**:
   - Prohibido versionar flags reales o credenciales en ramas públicas de desarrollo.
   - Usar flags dummy para pruebas locales (ej. `CHRONOS{test_flag_local_development}`) y definir la flag de producción en el despliegue final.
