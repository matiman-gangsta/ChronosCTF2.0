import subprocess

def run_query(sql):
    cmd = [
        "docker", "exec", "-i", "333ded6566e0_chronos_postgres_local",
        "psql", "-U", "postgres", "-d", "gzctf", "-x", "-c", sql
    ]
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.stdout, p.stderr

out, _ = run_query('SELECT * FROM "Containers" WHERE "Id" = \'01a0f4ed-1586-736e-95e6-3fee9df1b84d\';')
print("=== Instance Container ===")
print(out)
