import requests

s = requests.Session()

# 1. Login como Admin
login_url = "http://localhost:8888/api/account/login"
res = s.post(login_url, json={"userName": "Admin", "password": "AdminPassword123!"})
print("Login Admin:", res.status_code, res.text[:200])

# Probar endpoints de challenges para el juego 4
endpoints = [
    "/api/game/4/challenge",
    "/api/game/4/challenges",
    "/api/game/4",
    "/api/edit/games/4",
    "/api/edit/games/4/challenges"
]

for ep in endpoints:
    r = s.get(f"http://localhost:8888{ep}")
    print(f"{ep} => Status: {r.status_code} | Len: {len(r.text)} | Body: {r.text[:150]}")
