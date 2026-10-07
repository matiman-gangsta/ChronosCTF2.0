import re

path = "/opt/gzctf/docker-compose.yml"
content = open(path).read()

# Replace the cadvisor service block
pattern = r"  cadvisor:[\s\S]*?    networks:\n      - ctf_platform"

new_cadvisor = """  cadvisor:
    image: gcr.io/cadvisor/cadvisor:v0.51.0
    container_name: chronos_cadvisor
    restart: always
    command:
      - '--containerd=/run/containerd/containerd.sock'
      - '--containerd-namespace=moby'
      - '--disable_metrics=disk,diskIO'
      - '--housekeeping_interval=10s'
    volumes:
      - /:/rootfs:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /run/containerd/containerd.sock:/run/containerd/containerd.sock:ro
      - /sys/fs/cgroup:/sys/fs/cgroup:ro
    privileged: true
    devices:
      - /dev/kmsg
    networks:
      - ctf_platform"""

content = re.sub(pattern, new_cadvisor, content)
open(path, "w").write(content)
print("Updated cadvisor successfully")
