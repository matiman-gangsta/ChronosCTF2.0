# 📋 Writeup Oficial: Rastro Digital

| Campo | Detalle |
| :--- | :--- |
| **Categoría** | OSINT / Git Forensics |
| **Dificultad** | Fácil (Easy) |
| **Puntos** | 300 |
| **Flag** | `CHRONOS{git_commit_history_never_dies_1636}` (o `FLAG{...}`) |

---

## 1. Análisis del Archivo

Se proporciona el archivo comprimido `chronoscorp-deploy-scripts.zip`.
Al descomprimirlo, se observa un proyecto con su directorio oculto `.git`:

```bash
unzip chronoscorp-deploy-scripts.zip
cd chronoscorp-deploy-scripts
```

Si revisamos el contenido actual del repositorio, los archivos `.env.example`, `deploy.sh` y `utils.py` no contienen información confidencial directa.

---

## 2. Inspección del Historial de Git

Para inspeccionar qué cambios o eliminaciones se realizaron en los commits pasados:

```bash
git log -p
```
O bien:
```bash
git log --oneline
git show <hash_del_commit_anterior>
```

Al revisar las diferencias (`diff`) de los commits antiguos, se evidencia una modificación donde se eliminaron líneas que contenían la clave secreta o la bandera:

```diff
- DB_PASSWORD="FLAG{git_commit_history_never_dies_1636}"
+ DB_PASSWORD="REDACTED_SECRET"
```

**Bandera:**
```text
CHRONOS{git_commit_history_never_dies_1636}
(o alternativamente: FLAG{git_commit_history_never_dies_1636})
```
