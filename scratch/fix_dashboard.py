import json

path = "/opt/gzctf/monitoring/grafana/provisioning/dashboards/json/ctf_overview.json"
content = open(path).read()

# Replace capitalized Prometheus datasource UID with lowercase prometheus
content = content.replace('"uid": "Prometheus"', '"uid": "prometheus"')

# Also make container panels legend more informative:
# if {{name}} is a hash, let's use {{image}} or {{name}}
content = content.replace('"legendFormat": "{{name}}"', '"legendFormat": "{{image}}"')

open(path, "w").write(content)
print("Dashboard updated successfully")
