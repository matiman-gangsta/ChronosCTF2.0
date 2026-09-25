# Inyección Clásica

## Iniciar en Windows

Abre PowerShell en esta carpeta y ejecuta:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements.txt
.\.venv\Scripts\python.exe app.py
```

La aplicación quedará disponible en:

```text
http://127.0.0.1:5000
```

Para detenerla, presiona `Ctrl+C`.

## Iniciar con Docker

```powershell
docker compose up --build -d
```

La aplicación quedará disponible en:

```text
http://127.0.0.1:5000
```

Para detenerla:

```powershell
docker compose down
```
