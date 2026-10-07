#!/usr/bin/env python3
import os
from flask import Flask, Response, render_template, request

app = Flask(__name__)

# Soporte de flag dinamica (GZCTF / CTFd) con fallback a la flag oficial del torneo
FLAG = os.getenv("GZCTF_FLAG") or os.getenv("FLAG") or "CHRONOS{h1dd3n_c0mm3nts_4nd_r0b0ts_txt_9182}"


@app.route("/")
def index():
    debug_param = request.args.get("debug", "").strip().lower()
    debug_mode = debug_param in ["true", "1", "yes"]
    return render_template("index.html", debug_mode=debug_mode)


@app.route("/robots.txt")
def robots():
    content = "User-agent: *\nDisallow: /super-secret-admin-backup-panel\n"
    return Response(content, mimetype="text/plain")


@app.route("/super-secret-admin-backup-panel")
def secret_panel():
    return render_template("emergency_panel.html", flag=FLAG)


@app.route("/health")
def health():
    return {"status": "ok"}, 200


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    app.run(host="0.0.0.0", port=port)
