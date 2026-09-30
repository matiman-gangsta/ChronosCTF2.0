import os
import sqlite3
from pathlib import Path

from flask import Flask, flash, redirect, render_template, request, session, url_for


BASE_DIR = Path(__file__).resolve().parent
DATABASE = Path(os.getenv("DATABASE_PATH", str(BASE_DIR / "data" / "users.db")))
FLAG = os.getenv("GZCTF_FLAG") or os.getenv("FLAG") or "CHRONOS{sqli_bypass_tautology_login_6406}"


def create_app(test_config=None):
    app = Flask(__name__)
    
    # Prevenir falsificación de cookies de sesión: si no se especifica una clave
    # o si se usa el valor de demostración, se genera una clave criptográfica aleatoria.
    configured_secret = os.getenv("SECRET_KEY")
    if not configured_secret or configured_secret == "chronos_secret_key_inyeccion_clasica_2026":
        configured_secret = os.urandom(32).hex()

    app.config.from_mapping(
        SECRET_KEY=configured_secret,
        DATABASE=str(DATABASE),
    )

    if test_config:
        app.config.update(test_config)

    init_database(app.config["DATABASE"])

    @app.get("/")
    def index():
        if session.get("username"):
            return redirect(url_for("dashboard"))
        return render_template("login.html")

    @app.post("/login")
    def login():
        username = request.form.get("username", "")
        password = request.form.get("password", "")

        if not username or not password:
            flash("Debes completar ambos campos.", "error")
            return redirect(url_for("index"))

        # Vulnerabilidad intencional para el reto: los datos controlados por el
        # usuario se concatenan directamente en la sentencia SQL.
        query = (
            "SELECT id, username, display_name, role FROM users "
            f"WHERE username = '{username}' AND password = '{password}'"
        )

        try:
            with connect(app.config["DATABASE"]) as database:
                user = database.execute(query).fetchone()
        except sqlite3.Error:
            flash("Las credenciales no son válidas.", "error")
            return redirect(url_for("index"))

        if user is None:
            flash("Las credenciales no son válidas.", "error")
            return redirect(url_for("index"))

        session.clear()
        session["username"] = user["username"]
        session["display_name"] = user["display_name"]
        session["role"] = user["role"]
        return redirect(url_for("dashboard"))

    @app.get("/dashboard")
    def dashboard():
        if not session.get("username"):
            return redirect(url_for("index"))

        return render_template(
            "dashboard.html",
            username=session["username"],
            display_name=session["display_name"],
            role=session["role"],
            flag=FLAG if session["role"] == "admin" else None,
        )

    @app.post("/logout")
    def logout():
        session.clear()
        return redirect(url_for("index"))

    @app.get("/health")
    def health():
        return {"status": "ok"}

    return app


def connect(database_path):
    connection = sqlite3.connect(database_path)
    connection.row_factory = sqlite3.Row
    return connection


def init_database(database_path):
    path = Path(database_path)
    path.parent.mkdir(parents=True, exist_ok=True)

    with connect(path) as database:
        existing_columns = {
            row["name"] for row in database.execute("PRAGMA table_info(users)")
        }
        expected_columns = {"id", "username", "password", "display_name", "role"}
        if existing_columns and existing_columns != expected_columns:
            # Restaura automáticamente una base creada por la variante UNION.
            # La base solo contiene datos de demostración del reto.
            database.execute("DROP TABLE users")

        database.executescript(
            """
            CREATE TABLE IF NOT EXISTS users (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                username TEXT UNIQUE NOT NULL,
                password TEXT NOT NULL,
                display_name TEXT NOT NULL,
                role TEXT NOT NULL CHECK (role IN ('admin', 'user'))
            );
            """
        )

        # Serializa el seed cuando Gunicorn arranca varios workers a la vez.
        # INSERT OR IGNORE mantiene la operación idempotente.
        database.execute("BEGIN IMMEDIATE")
        # El administrador se inserta primero para que una tautología sin
        # ORDER BY devuelva esa cuenta de forma determinista en el reto.
        database.executemany(
            "INSERT OR IGNORE INTO users "
            "(username, password, display_name, role) VALUES (?, ?, ?, ?)",
            [
                ("admin", "7f9a2c1e-b4d8-49f0", "Administrator", "admin"),
                ("analyst", "quarterly-review-2026", "Nora Analyst", "user"),
                ("guest", "welcome-to-portal", "Guest Account", "user"),
            ],
        )


app = create_app()


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.getenv("PORT", "5000")))
