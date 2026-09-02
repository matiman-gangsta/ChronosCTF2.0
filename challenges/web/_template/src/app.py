#!/usr/bin/env python3
"""
ChronosCTF 2026 - Template Web Challenge Application
"""

import os
from flask import Flask, jsonify, request, render_template_string

app = Flask(__name__)

FLAG = os.environ.get("FLAG", "CHRONOS{d3fault_fl4g_f0r_t3mplat3_ch4ll3ng3}")
DEBUG_TOKEN = "chronos_internal_debug"

LANDING_PAGE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>ChronosCTF - Vault Gateway</title>
    <style>
        body {
            background-color: #0b0f19;
            color: #00ffcc;
            font-family: 'Courier New', Courier, monospace;
            display: flex;
            align-items: center;
            justify-content: center;
            height: 100vh;
            margin: 0;
        }
        .card {
            border: 1px solid #00ffcc;
            padding: 2.5rem;
            border-radius: 8px;
            box-shadow: 0 0 20px rgba(0, 255, 204, 0.2);
            text-align: center;
            max-width: 500px;
        }
        h1 { margin-top: 0; }
        p { color: #8892b0; }
        .endpoint {
            background: #111e33;
            padding: 8px 12px;
            border-radius: 4px;
            display: inline-block;
            margin-top: 10px;
            color: #ff79c6;
        }
    </style>
</head>
<body>
    <div class="card">
        <h1>🔒 ChronosCTF Vault Gateway</h1>
        <p>Servicio de verificación de credenciales de seguridad interna.</p>
        <p>Estado del sistema: <strong>OPERATIVO</strong></p>
        <div class="endpoint">API Vault: /api/v1/secret-vault</div>
    </div>
</body>
</html>
"""

@app.route("/", methods=["GET"])
def index():
    return render_template_string(LANDING_PAGE)

@app.route("/health", methods=["GET"])
def health():
    return jsonify({"status": "healthy", "service": "template-challenge"}), 200

@app.route("/api/v1/secret-vault", methods=["GET"])
def secret_vault():
    token = request.headers.get("X-Developer-Token")
    debug_mode = request.args.get("debug") == "1"

    if token == DEBUG_TOKEN or debug_mode:
        return jsonify({
            "status": "success",
            "message": "Vault unlocked! Welcome operator.",
            "flag": FLAG
        }), 200

    return jsonify({
        "status": "error",
        "message": "Access denied. Valid 'X-Developer-Token' header or debug permission required."
    }), 403

if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
