# Etapa de compilación: crea el binario intencionalmente vulnerable del reto.
FROM gcc:13-bookworm AS builder

WORKDIR /build
COPY privesc/report-helper.c .
RUN gcc -O2 -Wall -Wextra -o report-helper report-helper.c

# Etapa final: servidor web PHP/Apache autocontenido.
FROM php:8.2-apache

COPY apache/configgate.conf /etc/apache2/conf-available/configgate.conf
COPY src/ /var/www/html/
COPY --from=builder /build/report-helper /usr/local/bin/report-helper

COPY start-configgate.sh /usr/local/bin/start-configgate.sh

RUN a2enconf configgate \
    && useradd -m -s /bin/bash analyst \
    && printf '%s\n' 'FLAG{configgate_upload_6e21}' > /home/analyst/user.txt \
    && printf '%s\n' 'FLAG{configgate_path_hijack_91ad}' > /root/root.txt \
    && mkdir -p /var/www/html/attachments \
    && chown -R www-data:www-data /var/www/html/attachments \
    && chmod 755 /var/www/html /var/www/html/attachments \
    && chmod 644 /home/analyst/user.txt \
    && chmod 600 /root/root.txt \
    && chown root:root /usr/local/bin/report-helper \
    && chmod 4755 /usr/local/bin/report-helper \
    && chmod +x /usr/local/bin/start-configgate.sh

EXPOSE 80

CMD ["/usr/local/bin/start-configgate.sh"]
