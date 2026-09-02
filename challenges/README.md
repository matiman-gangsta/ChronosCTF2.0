# ChronosCTF 2026 - Repositorio de Retos (Challenges)

Este directorio alberga la totalidad de desafíos para el torneo **ChronosCTF 2026**. Todo autor de retos debe seguir la convención y las políticas descritas en este documento y en [.antigravity/rules.md](file:///c:/Users/Usuario/OneDrive%20-%20miuandes.cl/Escritorio/ChronosCTF%202.0/.antigravity/rules.md).

---

## 1. Categorías Oficiales

Organiza los retos dentro de su respectivo directorio por categoría:

- `web/`: Vulnerabilidades de aplicaciones web (SQLi, SSRF, XSS, Deserialización, IDOR, etc.).
- `pwn/`: Explotación de binarios en memoria (Buffer Overflow, ROP, Format Strings, Heap).
- `rev/`: Ingeniería inversa (Binarios ELF/PE, APKs Android, bytecode de Python, obfuscación).
- `crypto/`: Criptografía moderna y clásica, fallos en curvas elípticas, RSA, padding oracles.
- `forensics/`: Análisis de capturas de red (PCAP), memoria RAM, esteganografía, discos e imágenes forenses.
- `misc/`: Retos misceláneos, jailbreaks de LLMs, scripting, OSINT, hardware, esotéricos.

---

## 2. Estructura Estándar de un Reto

Cada reto debe ubicarse en su propia carpeta: `challenges/<categoria>/<nombre_del_reto>/`

Ejemplo de estructura mínima obligatoria:

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

---

## 3. Pasos para Crear un Nuevo Reto

1. **Copiar la plantilla base**:
   ```bash
   cp -r challenges/web/_template challenges/<categoria>/<tu-reto>
   ```
2. **Editar `challenge.yml`**:
   - Asignar nombre, descripción atractiva, dificultad (`easy`, `medium`, `hard`), puntaje y la bandera (`flag`).
3. **Implementar el código en `src/`**:
   - Asegurar que la flag pueda ser leída desde la variable de entorno `FLAG` o archivo `/flag.txt`.
4. **Modificar el `Dockerfile`**:
   - Utilizar imagen multi-stage basada en distros ligeras (`alpine` o `slim`).
   - Mantener el usuario no-root (`USER ctf`).
5. **Redactar el Writeup en `solution.md`**:
   - Explicar la causa raíz de la vulnerabilidad y adjuntar script de explotación en `solution/solve.py`.
6. **Probar localmente**:
   ```bash
   cd challenges/<categoria>/<tu-reto>
   docker build -t test-challenge .
   docker run -p 8000:8000 -e FLAG="CHRONOS{test_flag_local}" test-challenge
   ```
7. **Abrir Pull Request**:
   - El pipeline de CI validará automáticamente que el `Dockerfile` compile correctamente y cumpla las reglas de seguridad.
