import requests

s = requests.Session()
# Login como test (elpepe)
login_res = s.post("http://localhost:8888/api/account/login", json={"userName": "test", "password": "password"})
if login_res.status_code != 200:
    # intentar otras contrasenas comunes o recuperar de base de datos
    print("Login test failed:", login_res.status_code, login_res.text)
else:
    print("Login test OK")

# Intentar como Admin
s_admin = requests.Session()
s_admin.post("http://localhost:8888/api/account/login", json={"userName": "Admin", "password": "AdminPassword123!"})

# Probar endpoints del juego 4 y 3
for gid in [3, 4]:
    print(f"\n--- GAME {gid} ---")
    r1 = s_admin.get(f"http://localhost:8888/api/game/{gid}")
    print(f"/api/game/{gid} =>", r1.status_code, r1.text[:200])
    
    r2 = s_admin.get(f"http://localhost:8888/api/game/{gid}/scoreboard")
    print(f"/api/game/{gid}/scoreboard =>", r2.status_code, r2.text[:200])

    r3 = s_admin.get(f"http://localhost:8888/api/game/{gid}/challenges")
    print(f"/api/game/{gid}/challenges =>", r3.status_code, r3.text[:200])
