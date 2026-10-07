# El Validador Lógico

**Categoría:** Reversing  
**Dificultad:** Media  
**Puntos:** 250  

## Descripción

Se te entrega un binario ELF en C (`dist/validator`) que solicita una clave por línea de comandos:

```bash
./validator <clave>
```

Internamente valida la clave mediante operaciones lógicas (XOR y rotaciones de bits). Si la clave es correcta, el binario revela la bandera. Si es incorrecta, informa el fallo sin dar más pistas.

## Objetivo

1. Descarga y analiza `dist/validator` con Ghidra, IDA o Binary Ninja.
2. Ubica la función que valida la clave (revisa el flujo desde `main`).
3. Identifica el algoritmo de transformación aplicado a cada carácter de la entrada y los bytes objetivo con los que se compara.
4. Invierte el algoritmo (escribe un "keygen") para reconstruir la clave original.
5. Ejecuta el binario con la clave reconstruida para obtener la bandera.

## Distribución a Jugadores

- Distribuir exclusivamente el archivo `dist/validator`.
- El código fuente, Makefile y script de solución en `solution/` son confidenciales para la organización.

## Formato de la Bandera

`CHRONOS{...}`
