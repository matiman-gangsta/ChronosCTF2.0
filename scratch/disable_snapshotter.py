import json

path = "/etc/docker/daemon.json"
cfg = json.load(open(path))
if "features" not in cfg:
    cfg["features"] = {}
cfg["features"]["containerd-snapshotter"] = False
json.dump(cfg, open(path, "w"), indent=2)
print("Updated daemon.json successfully")
