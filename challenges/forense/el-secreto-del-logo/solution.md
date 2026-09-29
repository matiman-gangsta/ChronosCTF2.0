# 📋 Writeup Oficial: El Secreto del Logo

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | Forense / Metadata |
| **Dificultad** | Fácil (Easy) |
| **Puntos** | 200 |
| **Flag** | `CHRONOS{exif_metadata_hidden_2026_0913}` (o `FLAG{...}`) |

---

## 1. Análisis del Archivo

Se proporciona el archivo `chronos_logo.jpg`. Al abrirlo con un visor de imágenes tradicional, solo se visualiza el logotipo corporativo.

Para analizar información oculta en el formato JPEG, podemos inspeccionar:
1. Metadatos EXIF.
2. Cadenas imprimibles incrustadas (`strings`).

---

## 2. Resolución

### Opción A: Usando `exiftool`
```bash
exiftool chronos_logo.jpg
```
Al inspeccionar la salida, en los campos de comentarios o descripción se encuentra la bandera oculta.

### Opción B: Usando `strings`
```bash
strings chronos_logo.jpg | grep -i "FLAG{"
```

### Opción C: Usando Python
```python
with open("chronos_logo.jpg", "rb") as f:
    data = f.read()
import re
print(re.search(r"FLAG\{[^}]+\}", data.decode("latin-1")).group(0))
```

**Resultado:**
```text
CHRONOS{exif_metadata_hidden_2026_0913}
(o alternativamente: FLAG{exif_metadata_hidden_2026_0913})
```
