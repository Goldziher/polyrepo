"""Record the system hook channel in each given repository's gitignored poly.local.toml.

Poly reads [hook_preferences] only from the repository it installs into (or, in a linked worktree,
from the main checkout), never from a parent directory, so every repository with external hook
sources needs its own copy.
"""

import pathlib
import subprocess
import sys
import tomllib


def ensure(repo: pathlib.Path) -> None:
    path = repo / "poly.local.toml"
    text = path.read_text() if path.exists() else ""
    preferences = tomllib.loads(text).get("hook_preferences")
    if preferences is None:
        ignored = subprocess.run(["git", "-C", str(repo), "check-ignore", "-q", "poly.local.toml"])
        if ignored.returncode != 0:
            raise SystemExit(f"{path} is not gitignored; add poly.local.toml to {repo}/.gitignore first")
        separator = "\n\n" if text.strip() else ""
        path.write_text(text.rstrip() + separator + '[hook_preferences]\nchannels = ["system"]\n')
    elif "system" not in preferences.get("channels", []):
        raise SystemExit(f"Add system to hook_preferences.channels in {path}")


for argument in sys.argv[1:]:
    ensure(pathlib.Path(argument))
