#!/usr/bin/env python3
# MISE description="Provision machine preferences and install reviewed AI governance hooks in the polyrepo root"
# MISE tools={python = "3.15.2", "github:Goldziher/poly" = "0.32.1"}
import os
import pathlib
import shutil
import subprocess
import sys

root = pathlib.Path(os.environ["MISE_CONFIG_ROOT"])
if shutil.which("ai-rulez") is None:
    raise SystemExit("ai-rulez is not on PATH; install it with npm install -g ai-rulez@latest (Node 22 or later)")
subprocess.run([sys.executable, str(root / "mise-tasks/.lib/hook_preferences.py"), str(root)], check=True)
subprocess.run(["poly", "hooks", "install"], check=True, cwd=root)
