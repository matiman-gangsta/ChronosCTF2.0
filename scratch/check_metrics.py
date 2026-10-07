import subprocess
import json

out = subprocess.check_output(["docker", "exec", "chronos_prometheus", "wget", "-qO-", "http://localhost:9090/api/v1/query?query=container_memory_usage_bytes"]).decode()
data = json.loads(out)
found = 0
for item in data.get("data", {}).get("result", []):
    metric = item.get("metric", {})
    val = item.get("value", [])
    if metric.get("name") or "docker" in metric.get("id", "") or metric.get("image"):
        print("FOUND CONTAINER METRIC:", metric, val)
        found += 1

print(f"Total container metrics found: {found}")
