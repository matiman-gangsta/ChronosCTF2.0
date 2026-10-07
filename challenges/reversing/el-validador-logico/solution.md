# Solución — El Validador Lógico

| Desafío | Categoría | Dificultad | Puntos | Flag |
| :--- | :--- | :--- | :--- | :--- |
| **El Validador Lógico** | Reversing | Media | 250 | `CHRONOS{GUID}` / `flag{GUID}` |

---

## 1. Reconocimiento inicial

Al ejecutar el binario sin argumentos:

```bash
$ ./dist/validator
Uso: ./validator <clave>
```

Con una clave de prueba cualquiera:

```bash
$ ./dist/validator prueba123
[-] Clave incorrecta.
```

---

## 2. Análisis estático en Ghidra

Al cargar `validator` en Ghidra o IDA y descompilar la función `main`, se observa el siguiente flujo:

1. El programa verifica `argc >= 2` (la clave se pasa como argumento de línea de comandos).
2. Se evalúa `check_key(argv[1])`.
3. Si `check_key` retorna verdadero (`1`), se ejecuta `decode_and_print_flag(argv[1])`.

### Descompilación de `check_key`:

```c
int check_key(const char *input) {
    size_t len = strlen(input);
    if (len != sizeof(target))      // target tiene 16 bytes
        return 0;
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)input[i];
        unsigned char x = c ^ 0x5A;                     // XOR con byte fijo 0x5A
        unsigned char r = rotl8(x, (int)((i % 4) + 1)); // rotación a la izquierda variable (1..4)
        if (r != target[i])
            return 0;
    }
    return 1;
}
```

Y la función de rotación auxiliar `rotl8`:

```c
unsigned char rotl8(unsigned char v, int r) {
    r %= 8;
    return (v << r) | (v >> (8 - r));
}
```

El arreglo `target[]` (almacenado en la sección `.data`, visible con `objdump -s -j .data validator` o Ghidra) contiene 16 bytes:
`0x04, 0xd4, 0x41, 0x50, 0x10, 0xd4, 0x71, 0xb3, 0x5c, 0xfc, 0x28, 0x11, 0x7e, 0x8c, 0x1b, 0x36`

Esto indica que la clave correcta tiene exactamente 16 caracteres.

---

## 3. Inversión del algoritmo (Keygen)

Para cada posición `i` (donde `shift = (i % 4) + 1`), la transformación hacia delante es:

$$r = \text{rotl8}(c \oplus 0\text{x5A}, \text{shift})$$

Dado que la rotación de 8 bits y el XOR son operaciones completamente biyectivas e invertibles:

$$x = \text{rotr8}(r, \text{shift})$$
$$c = x \oplus 0\text{x5A}$$

Al implementar esto en un script en Python:

```python
TARGET_BYTES = [0x04, 0xd4, 0x41, 0x50, 0x10, 0xd4, 0x71, 0xb3,
                0x5c, 0xfc, 0x28, 0x11, 0x7e, 0x8c, 0x1b, 0x36]

def rotr8(v, r):
    r %= 8
    return ((v >> r) | (v << (8 - r))) & 0xFF

key = "".join(chr(rotr8(r, (i % 4) + 1) ^ 0x5A) for i, r in enumerate(TARGET_BYTES))
print("Clave:", key)  # Xor_Rotate_Key99
```

---

## 4. Obtención de la bandera

Al ejecutar el binario con la clave calculada (`Xor_Rotate_Key99`):

```bash
$ ./dist/validator Xor_Rotate_Key99
[+] Clave valida. Acceso concedido.
[+] Bandera: CHRONOS{4c8d2e1f-7b3a-4950-86c1-9e2f3a4b5c6d}
```

La bandera se genera descifrando `enc_flag[]` mediante XOR cíclico con la clave secreta, impidiendo que pueda ser extraída simplemente con el comando `strings`.

---

## 5. Verificación automática

El script oficial de resolución se encuentra en `solution/solve.py`:

```bash
cd solution
python3 solve.py
```

Salida esperada:
```text
[*] Invirtiendo el algoritmo XOR + rotacion identificado en Ghidra...
[+] Clave reconstruida: Xor_Rotate_Key99
[*] Ejecutando el binario con la clave reconstruida: ../dist/validator
==================================================
[+] Clave valida. Acceso concedido.
[+] Bandera: CHRONOS{4c8d2e1f-7b3a-4950-86c1-9e2f3a4b5c6d}
==================================================

[+] [FLAG RECUPERADA] => CHRONOS{4c8d2e1f-7b3a-4950-86c1-9e2f3a4b5c6d}
```
