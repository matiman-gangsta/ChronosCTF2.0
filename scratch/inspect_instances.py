import subprocess

def run_query(sql):
    cmd = [
        "docker", "exec", "-i", "333ded6566e0_chronos_postgres_local",
        "psql", "-U", "postgres", "-d", "gzctf", "-x", "-c", sql
    ]
    p = subprocess.run(cmd, capture_output=True, text=True)
    return p.stdout, p.stderr

out, _ = run_query('''
SELECT gi."ChallengeId", gc."Title", gi."FlagId", fc."Flag", c."PublicIP", c."PublicPort"
FROM "GameInstances" gi
JOIN "GameChallenges" gc ON gi."ChallengeId" = gc."Id"
LEFT JOIN "FlagContexts" fc ON gi."FlagId" = fc."Id"
LEFT JOIN "Containers" c ON gi."ContainerId" = c."Id"
WHERE gi."ParticipationId" = 9;
''')
print("=== Active Instances for elpepe ===")
print(out)
