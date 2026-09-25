import os
from pathlib import Path

from flask import Flask, render_template, request


BASE_DIR = Path(__file__).resolve().parent
ARCHIVE_ROOT = BASE_DIR / "archive" / "public"
DEFAULT_DOCUMENT = "welcome.txt"


def create_app(test_config=None):
    app = Flask(__name__)
    app.config.from_mapping(
        ARCHIVE_ROOT=str(ARCHIVE_ROOT),
    )

    if test_config:
        app.config.update(test_config)

    @app.get("/")
    def index():
        requested_file = request.args.get("view", DEFAULT_DOCUMENT)
        content = None
        error = None

        # Control incompleto e intencional: solo valida la extensión. La ruta
        # recibida se une directamente a la raíz sin resolver ni comprobar que
        # permanezca dentro del archivo público.
        if not requested_file.lower().endswith(".txt"):
            error = "Formato no admitido. El visor solo procesa archivos TXT."
        else:
            target = Path(app.config["ARCHIVE_ROOT"]) / requested_file
            try:
                content = target.read_text(encoding="utf-8")
            except (OSError, UnicodeError):
                error = "No fue posible localizar o procesar el documento solicitado."

        documents = [
            {
                "name": "welcome.txt",
                "title": "Protocolo de bienvenida",
                "tag": "GENERAL",
            },
            {
                "name": "network-notes.txt",
                "title": "Notas de infraestructura",
                "tag": "NETWORK",
            },
            {
                "name": "incident-2026.txt",
                "title": "Incidente #041",
                "tag": "RESTRICTED",
            },
        ]

        return render_template(
            "index.html",
            documents=documents,
            requested_file=requested_file,
            content=content,
            error=error,
        )

    @app.get("/health")
    def health():
        return {"status": "ok"}

    return app


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5001")))
