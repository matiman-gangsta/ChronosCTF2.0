/*
 * El Validador Logico
 * Reto de Reversing - valida una clave mediante XOR + rotacion de bits.
 * Si la clave es correcta, descifra y muestra la flag con formato GUID.
 */
#include <stdio.h>
#include <string.h>
#include <stdlib.h>

/* Bytes objetivo: transformacion de la clave secreta (XOR 0x5A + ROL variable) */
unsigned char target[] = {0x04, 0xd4, 0x41, 0x50, 0x10, 0xd4, 0x71, 0xb3, 0x5c, 0xfc, 0x28, 0x11, 0x7e, 0x8c, 0x1b, 0x36};

/* Flag cifrada con XOR repitiendo la clave secreta como stream (CHRONOS{4c8d2e1f-7b3a-4950-86c1-9e2f3a4b5c6d}) */
unsigned char enc_flag[] = {0x1b, 0x27, 0x20, 0x10, 0x1c, 0x20, 0x27, 0x1a, 0x40, 0x06, 0x67, 0x2f, 0x57, 0x1c, 0x08, 0x5f, 0x75, 0x58, 0x10, 0x6c, 0x33, 0x42, 0x40, 0x58, 0x41, 0x55, 0x72, 0x73, 0x53, 0x1a, 0x08, 0x14, 0x61, 0x0a, 0x40, 0x39, 0x61, 0x0e, 0x40, 0x03, 0x41, 0x06, 0x69, 0x2f, 0x18};

unsigned char rotl8(unsigned char v, int r) {
    r %= 8;
    if (r == 0) return v;
    return (unsigned char)((v << r) | (v >> (8 - r)));
}

int check_key(const char *input) {
    size_t len = strlen(input);
    if (len != sizeof(target)) {
        return 0;
    }
    for (size_t i = 0; i < len; i++) {
        unsigned char c = (unsigned char)input[i];
        unsigned char x = c ^ 0x5A;
        unsigned char r = rotl8(x, (int)((i % 4) + 1));
        if (r != target[i]) {
            return 0;
        }
    }
    return 1;
}

void decode_and_print_flag(const char *input) {
    size_t klen = strlen(input);
    size_t n = sizeof(enc_flag);
    for (size_t i = 0; i < n; i++) {
        unsigned char kb = (unsigned char)input[i % klen];
        putchar(enc_flag[i] ^ kb);
    }
    putchar('\n');
}

int main(int argc, char **argv) {
    if (argc < 2) {
        printf("Uso: %s <clave>\n", argv[0]);
        return 1;
    }

    if (check_key(argv[1])) {
        printf("[+] Clave valida. Acceso concedido.\n");
        printf("[+] Bandera: ");
        decode_and_print_flag(argv[1]);
    } else {
        printf("[-] Clave incorrecta.\n");
        return 1;
    }

    return 0;
}
