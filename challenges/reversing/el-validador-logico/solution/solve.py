#!/usr/bin/env python3
"""
solve.py - Resolutor automático para "El Validador Lógico" (Soporta GUIDs de GZCTF)

Este script reconstruye la clave invirtiendo el algoritmo (XOR 0x5A + rotación
de bits variable) identificado en Ghidra (función check_key). Luego ejecuta el
binario con la clave reconstruida y valida que la bandera extraída (con formato GUID)
sea correcta.

Uso:
    python3 solve.py [--binary ../dist/validator]
"""
import argparse
import subprocess
import sys
import re

# Extraídos leyendo el arreglo global "target" en el binario (.data)
TARGET_BYTES = [0x04, 0xd4, 0x41, 0x50, 0x10, 0xd4, 0x71, 0xb3,
                 0x5c, 0xfc, 0x28, 0x11, 0x7e, 0x8c, 0x1b, 0x36]


def rotr8(v: int, r: int) -> int:
    """Inversa de rotl8: rotación a la derecha de 8 bits."""
    r %= 8
    if r == 0:
        return v & 0xFF
    return ((v >> r) | (v << (8 - r))) & 0xFF


def recover_key(target: list) -> str:
    """
    Invierte check_key():
        r = rotl8(c ^ 0x5A, (i % 4) + 1)
    =>  x = rotr8(r, (i % 4) + 1)
        c = x ^ 0x5A
    """
    recovered = []
    for i, r in enumerate(target):
        shift = (i % 4) + 1
        x = rotr8(r, shift)
        c = x ^ 0x5A
        recovered.append(chr(c))
    return "".join(recovered)


def main():
    parser = argparse.ArgumentParser(description="Resuelve el reto El Validador Lógico")
    parser.add_argument("--binary", default="../dist/validator", help="Ruta al binario validator")
    args = parser.parse_args()

    print("[*] Invirtiendo el algoritmo XOR + rotación identificado en Ghidra...")
    key = recover_key(TARGET_BYTES)
    print(f"[+] Clave reconstruida: {key}")

    print(f"[*] Ejecutando el binario con la clave reconstruida: {args.binary}")
    try:
        result = subprocess.run(
            [args.binary, key],
            capture_output=True,
            text=True,
            timeout=5,
        )
    except FileNotFoundError:
        print(f"[!] No se encontró el binario en {args.binary}")
        sys.exit(1)

    print("=" * 50)
    print(result.stdout.strip())
    print("=" * 50)

    if result.returncode != 0:
        print("[!] El binario devolvió un error. La clave reconstruida podría ser incorrecta.")
        sys.exit(1)

    # Validar extracción de bandera compatible con formato GUID / GZCTF
    match = re.search(r"(?:CHRONOS|FLAG|flag)\{[a-zA-Z0-9_\-]{8,64}\}", result.stdout)
    if match:
        flag = match.group(0)
        print(f"\n[+] [FLAG RECUPERADA] => {flag}\n")
        sys.exit(0)
    else:
        print("[!] No se pudo extraer la bandera de la salida del binario.")
        sys.exit(1)


if __name__ == "__main__":
    main()
