FROM php:8.2-apache

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get install -y --no-install-recommends openssh-server apache2-utils ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY apache/nightfall-vhosts.conf /etc/apache2/sites-available/nightfall-vhosts.conf
COPY apache/nightfall-servername.conf /etc/apache2/conf-available/nightfall-servername.conf
COPY apache/sshd_config /etc/ssh/sshd_config
COPY src/public/ /var/www/public/
COPY src/console/ /var/www/console/
COPY wordlists/nightfall.txt /opt/nightfall/nightfall.txt
COPY start-nightfall.sh /usr/local/bin/start-nightfall.sh

RUN a2dissite 000-default \
    && a2ensite nightfall-vhosts \
    && a2enconf nightfall-servername \
    && a2enmod rewrite \
    && useradd -m -s /bin/bash archivist \
    && mkdir -p /home/archivist/.ssh /run/sshd /opt/nightfall \
    && ssh-keygen -q -t ed25519 -N '' -f /home/archivist/.ssh/id_ed25519 \
    && cp /home/archivist/.ssh/id_ed25519.pub /home/archivist/.ssh/authorized_keys \
    && printf '%s\n' 'FLAG{nightfall_ssh_path_4b7a}' > /home/archivist/user.txt \
    && printf '%s\n' 'FLAG{nightfall_ab_shadow_90c2}' > /root/root.txt \
    && echo 'root:nightfall42' | chpasswd \
    && chown -R archivist:archivist /home/archivist \
    && chmod 755 /home/archivist/.ssh \
    && chmod 644 /home/archivist/.ssh/id_ed25519 \
    && chmod 600 /home/archivist/.ssh/authorized_keys \
    && chmod 644 /home/archivist/user.txt \
    && chmod 600 /root/root.txt \
    && test -x /usr/bin/ab \
    && chown root:root /usr/bin/ab \
    && chmod 4755 /usr/bin/ab \
    && chmod +x /usr/local/bin/start-nightfall.sh

EXPOSE 80 22

CMD ["/usr/local/bin/start-nightfall.sh"]
