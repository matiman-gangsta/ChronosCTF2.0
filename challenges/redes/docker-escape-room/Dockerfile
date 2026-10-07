# "challenge": entorno SSH con privilegios limitados (usuario ctfuser) que
# tiene alcance al socket de Docker expuesto por el contenedor "docker-host".
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openssh-server \
        docker.io \
        ca-certificates \
        curl \
    && rm -rf /var/lib/apt/lists/*

# Configuración de SSH
RUN ssh-keygen -A && \
    sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config

# Usuario sin privilegios de sudo ni pertenencia al grupo docker
RUN useradd -m -s /bin/bash ctfuser && \
    echo "ctfuser:ctf_docker_2024" | chpasswd

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 22
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
