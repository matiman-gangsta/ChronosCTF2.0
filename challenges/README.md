# ChronosCTF 2026 - Repositorio de Retos (Challenges)

Este directorio alberga la totalidad de desafíos para el torneo **ChronosCTF 2026**. Todo autor de retos debe seguir la convención y las políticas descritas en este documento y en [.antigravity/rules.md](../.antigravity/rules.md).

---

## 1. Categorías Oficiales

Organiza los retos dentro de su respectivo directorio por categoría:

- `web/`: Vulnerabilidades de aplicaciones web (SQLi, Command Injection, LFI/Path Traversal, SSRF, IDOR, etc.).
- `forense/`: Análisis de archivos, metadatos EXIF, esteganografía, capturas de red (PCAP) e imágenes de disco/memoria.
- `osint/`: Inteligencia en fuentes abiertas, análisis de historiales Git, fugas de credenciales y footprinting.
- `pwn/`: Explotación de binarios en memoria (Buffer Overflow, ROP, Format Strings, Heap).
- `rev/`: Ingeniería inversa (Binarios ELF/PE, APKs Android, bytecode de Python, desobfuscación).
- `crypto/`: Criptografía moderna y clásica, fallos en curvas elípticas, debilidades en RSA, padding oracles.
- `misc/`: Retos misceláneos, jailbreaks de LLMs, scripting y desafíos no catalogados.

---

## 2. Tipos de Retos y Estructura Estándar

Cada reto debe residir en su propia carpeta: `challenges/<categoria>/<nombre_del_reto>/`

### A. Retos Dinámicos (Servicios Containerizados - Web / Pwn)
Requieren ejecución de un contenedor Docker aislado:

```text
challenges/web/ejemplo-inyeccion/
├── Dockerfile              # Receta multi-stage, usuario no-root, puerto expuesto
├── challenge.yml           # Metadatos para sincronización con CTFd (ctfcli)
├── solution.md             # Writeup oficial y guía de solución
├── solution/               # Script de exploit automatizado (solve.py)
│   └── solve.py
└── src/                    # Código fuente del reto
    ├── app.py
    └── requirements.txt
```

### B. Retos Estáticos (Archivos para Descarga - Forense / OSINT / Cripto / Rev)
No requieren contenedor Docker en runtime. El participante descarga un archivo adjunto:

```text
challenges/forense/el-secreto-del-logo/
├── challenge.yml           # Metadatos con sección 'files:' declarando los adjuntos
├── solution.md             # Writeup oficial con pasos analíticos o scripts locales
└── chronos_logo.jpg        # Archivo(s) distribuidos a los competidores
```

---

## 3. Pasos para Crear un Nuevo Reto

### Para retos con contenedor (Web / Pwn):
1. **Copiar la plantilla base**:
   ```bash
   cp -r challenges/web/_template challenges/<categoria>/<tu-reto>
   ```
2. **Editar `challenge.yml`**:
   - Asignar nombre, descripción atractiva, dificultad (`easy`, `medium`, `hard`), puntaje y la bandera obligatoria (`CHRONOS{...}`).
3. **Implementar el código en `src/`**:
   - Asegurar que la bandera se inyecte vía variable de entorno `FLAG` o archivo `/flag.txt`.
4. **Modificar el `Dockerfile`**:
   - Utilizar imagen multi-stage basada en distros ligeras (`alpine` o `slim`).
   - Mantener rigurosamente el usuario no-root (`USER ctf`).
5. **Redactar el Writeup en `solution.md`**:
   - Explicar la causa raíz de la vulnerabilidad y adjuntar script en `solution/solve.py`.
6. **Probar localmente**:
   ```bash
   cd challenges/<categoria>/<tu-reto>
   docker build -t test-challenge .
   docker run -p 8000:8000 -e FLAG="CHRONOS{test_flag_local}" test-challenge
   ```

### Para retos estáticos (Forense / OSINT / Cripto):
1. Crear el directorio `challenges/<categoria>/<tu-reto>/`.
2. Incluir el archivo o recurso descargable.
3. Crear el `challenge.yml` indicando el path en la propiedad `files:`.
4. Documentar detalladamente los pasos de resolución en `solution.md` (y script de resolución si aplica).
5. Asegurar que la flag respete el formato oficial: `CHRONOS{...}`.

---

## 4. Integración Continua (CI)
Al abrir un Pull Request a `main`:
- El pipeline `build-challenges.yml` detectará automáticamente las carpetas modificadas.
- Validará la presencia obligatoria de `challenge.yml` y `solution.md`.
- En retos con `Dockerfile`, compilará la imagen y verificará que el contenedor se ejecute con usuario sin privilegios (no-root).
