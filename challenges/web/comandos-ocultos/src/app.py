#!/usr/bin/env python3
"""
ChronosCTF 2026 - Reto Web: Comandos Ocultos (PingTool Pro)
Vulnerabilidad intencionada: Command Injection con WAF Blacklist Bypass.
"""

import subprocess
from flask import Flask, request, render_template_string

app = Flask(__name__)

# WAF / Blacklist intencionada:
# - Bloquea espacios (' ')
# - Bloquea el comando directo 'cat' y la palabra 'flag'
# - Bloquea punto y coma ';'
BLOCKED_KEYWORDS = ["cat", "flag"]
BLOCKED_CHARS = [";", " "]


def waf_check(user_input: str):
    for char in BLOCKED_CHARS:
        if char in user_input:
            return False, f"Carácter no permitido: {repr(char)}"

    lower_input = user_input.lower()
    for kw in BLOCKED_KEYWORDS:
        if kw in lower_input:
            return False, f"Palabra clave prohibida: '{kw}'"

    return True, ""


HTML_TEMPLATE = r"""
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PingTool Pro — Panel de Diagnóstico | ChronosCTF</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Consolas', 'Courier New', monospace;
            background: #0d1117;
            color: #c9d1d9;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 20px;
        }
        .card {
            background: #161b22;
            border: 1px solid #30363d;
            border-radius: 8px;
            width: 650px;
            max-width: 95vw;
            box-shadow: 0 8px 24px rgba(0,0,0,0.5);
            overflow: hidden;
        }
        .header {
            background: #21262d;
            padding: 12px 18px;
            display: flex;
            align-items: center;
            justify-content: space-between;
            border-bottom: 1px solid #30363d;
        }
        .badge {
            background: #d29922;
            color: #0d1117;
            font-size: 11px;
            font-weight: bold;
            padding: 3px 8px;
            border-radius: 12px;
            text-transform: uppercase;
        }
        .body { padding: 22px; }
        h1 {
            font-size: 18px;
            color: #58a6ff;
            margin-bottom: 6px;
        }
        p.desc {
            color: #8b949e;
            font-size: 13px;
            margin-bottom: 18px;
        }
        form { display: flex; gap: 8px; }
        input[type="text"] {
            flex: 1;
            padding: 10px 14px;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            color: #f0f6fc;
            font-family: inherit;
            font-size: 14px;
            outline: none;
        }
        input[type="text"]:focus { border-color: #58a6ff; }
        button {
            padding: 10px 22px;
            background: #238636;
            border: none;
            border-radius: 6px;
            color: #fff;
            font-weight: bold;
            cursor: pointer;
            transition: background 0.2s;
        }
        button:hover { background: #2ea043; }
        .output {
            margin-top: 18px;
            background: #0d1117;
            border: 1px solid #30363d;
            border-radius: 6px;
            padding: 14px;
            white-space: pre-wrap;
            font-size: 13px;
            color: #7ee787;
            max-height: 320px;
            overflow-y: auto;
        }
        .error {
            color: #f85149;
            border-color: #f8514944;
        }
        .footer {
            padding: 10px;
            text-align: center;
            font-size: 11px;
            color: #484f58;
            border-top: 1px solid #21262d;
        }
    </style>
</head>
<body>
    <div class="card">
        <div class="header">
            <span style="color:#58a6ff; font-weight:bold;">pingtool@chronos-infra</span>
            <span class="badge">WAF Filter Active</span>
        </div>
        <div class="body">
            <h1>📡 PingTool Pro</h1>
            <p class="desc">Herramienta interna de diagnóstico de conectividad ICMP con filtrado perimetral.</p>
            <form method="POST">
                <input type="text" name="host" placeholder="Ej: 127.0.0.1" value="{{ host }}" autocomplete="off" required />
                <button type="submit">Diagnosticar</button>
            </form>

            {% if blocked %}
            <div class="output error">[!] WAF DETECCIÓN: {{ blocked }}</div>
            {% elif output %}
            <div class="output">{{ output }}</div>
            {% endif %}
        </div>
        <div class="footer">ChronosCTF 2026 • Categoría Web • Dificultad Media</div>
    </div>
</body>
</html>
"""


@app.route("/", methods=["GET", "POST"])
def index():
    output = ""
    host = ""
    blocked = ""

    if request.method == "POST":
        host = request.form.get("host", "").strip()
        allowed, reason = waf_check(host)

        if not allowed:
            blocked = reason
        else:
            # Vulnerabilidad intencionada: concatenación directa con shell=True
            command = f"ping -c 2 {host}"
            try:
                result = subprocess.run(
                    command,
                    shell=True,
                    capture_output=True,
                    text=True,
                    timeout=5,
                )
                output = (result.stdout + result.stderr).strip()
            except subprocess.TimeoutExpired:
                output = "[!] Error: Tiempo de espera agotado (timeout)."
            except Exception as e:
                output = f"[!] Error de ejecución: {e}"

    return render_template_string(
        HTML_TEMPLATE, output=output, host=host, blocked=blocked
    )


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
