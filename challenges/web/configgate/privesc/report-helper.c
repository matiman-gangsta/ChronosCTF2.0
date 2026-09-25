#include <unistd.h>

/*
 * Utilidad de informes instalada por el equipo de operaciones.
 *
 * El reto deja este binario como SUID root y resuelve "tar" a través del
 * PATH heredado. Esa combinación es deliberadamente insegura y constituye
 * la segunda etapa de escalada del laboratorio.
 */
int main(void) {
    char *const args[] = {
        "sh",
        "-p",
        "-c",
        "tar -czf /tmp/site-report.tgz /var/www/html",
        NULL
    };

    if (setgid(0) != 0 || setuid(0) != 0) {
        return 1;
    }

    execv("/bin/sh", args);
    return 1;
}
