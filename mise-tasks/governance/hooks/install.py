#!/usr/bin/env python3
# MISE description="Provision machine preferences and install reviewed AI governance hooks"
# MISE tools={python = "3.15.2", "github:Goldziher/poly" = "0.32.1"}
import pathlib
import shutil
import subprocess
import tomllib

if shutil.which("ai-rulez") is None:
    raise SystemExit("ai-rulez is not on PATH; install it with npm install -g ai-rulez@latest (Node 22 or later)")
preferences = pathlib.Path("poly.local.toml")
text = preferences.read_text() if preferences.exists() else ""
data = tomllib.loads(text)
if "hook_preferences" not in data:
    preferences.write_text(text.rstrip() + '\n\n[hook_preferences]\nchannels = ["system"]\n')
elif "system" not in data["hook_preferences"].get("channels", []):
    raise SystemExit("Add system to hook_preferences.channels in poly.local.toml")
subprocess.run(["poly", "hooks", "install"], check=True)
