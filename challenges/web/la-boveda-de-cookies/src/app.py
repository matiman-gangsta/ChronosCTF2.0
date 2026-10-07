#!/usr/bin/env python3
"""
La Bóveda de Cookies (ChronosCTF 2026)
Categoría: Web
Dificultad: Fácil (Easy)
Vulnerabilidad: Manipulación de cookie de sesión sin firma criptográfica
"""

import base64
import json
import os
import time
from flask import Flask, make_response, redirect, render_template, request, url_for

app = Flask(__name__)

# Soporte de flag dinamica (GZCTF / CTFd)
FLAG = os.getenv("GZCTF_FLAG") or os.getenv("FLAG") or "CHRONOS{c00k13_m4n1pul4t10n_uns1gn3d_v4ult_4921}"

# Usuarios registrados en el sistema
USERS_DB = {
    "invitado": "invitado123",
    "empleado": "cybercorp_emp_2026",
}


def decode_session(cookie_value):
    """
    Decodifica la cookie de sesion provista por el cliente.
    Al no poseer firma criptografica (HMAC / Secret Key),
    el servidor confia ciegamente en el contenido provisto.
    """
    if not cookie_value:
        return None
    try:
        # Intento 1: Decodificar Base64
        padded = cookie_value + "=" * ((4 - len(cookie_value) % 4) % 4)
        raw_json = base64.b64decode(padded.encode()).decode("utf-8")
        return json.loads(raw_json)
    except Exception:
        try:
            # Intento 2: JSON directo
            return json.loads(cookie_value)
        except Exception:
            return None


def encode_session(data):
    """Serializa los datos de sesion en Base64 sin firma."""
    raw_json = json.dumps(data)
    return base64.b64encode(raw_json.encode()).decode("utf-8")


@app.route("/")
def index():
    raw_cookie = request.cookies.get("vault_session")
    session_data = decode_session(raw_cookie)

    # Tambien soportar cookie directa role=admin para maxima accesibilidad
    simple_role_cookie = request.cookies.get("role")

    if not session_data and not simple_role_cookie:
        return redirect(url_for("login"))

    user = session_data or {"username": "invitado", "role": simple_role_cookie or "guest"}
    role = (simple_role_cookie or user.get("role", "guest")).strip().lower()
    is_admin = role in ["admin", "administrator", "root"]

    raw_display = raw_cookie if raw_cookie else f"role={simple_role_cookie}"
    try:
        decoded_text = base64.b64decode(raw_cookie).decode("utf-8") if raw_cookie else f'{{"role": "{simple_role_cookie}"}}'
        display_data = f"Base64 Raw: {raw_display}\nDecoded JSON: {decoded_text}"
    except Exception:
        display_data = raw_display

    return render_template(
        "vault.html",
        user=user,
        is_admin=is_admin,
        flag=FLAG,
        raw_cookie_data=display_data,
    )


@app.route("/login", methods=["GET", "POST"])
def login():
    error = None
    if request.method == "POST":
        username = request.form.get("username", "").strip()
        password = request.form.get("password", "").strip()

        if username in USERS_DB and USERS_DB[username] == password:
            session_payload = {
                "username": username,
                "role": "guest" if username == "invitado" else "user",
                "auth_time": int(time.time()),
            }
            cookie_val = encode_session(session_payload)

            response = make_response(redirect(url_for("index")))
            # Configuracion insegura intencional: sin HttpOnly ni firma HMAC
            response.set_cookie("vault_session", cookie_val, path="/")
            return response
        else:
            error = "Credenciales invalidas. Utiliza la cuenta de invitado provista."

    return render_template("login.html", error=error)


@app.route("/logout")
def logout():
    response = make_response(redirect(url_for("login")))
    response.delete_cookie("vault_session", path="/")
    response.delete_cookie("role", path="/")
    return response


@app.route("/health")
def health():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
