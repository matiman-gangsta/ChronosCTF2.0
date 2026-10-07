CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra
STRIP ?= strip

TARGET = ../dist/validator
SRC = validator.c

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(SRC)
	@mkdir -p ../dist
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)
	$(STRIP) --strip-all $(TARGET)
	@echo "[+] Compilado exitosamente en $(TARGET)"

clean:
	rm -f $(TARGET)
