"""Report ai-rulez outputs that git would pick up as new files.

Every file in a generated manifest must be either tracked (committed on purpose, usually through
gitignore_exclude) or gitignored. Exits 1 when any repository has a loose output or was never
generated.
"""

import json
import os
import pathlib
import subprocess
import sys
from collections.abc import Iterator

SKIP = {".git", ".worktrees", "node_modules", "target", "plugin"}
SKIP_PATHS = {"tests/fixtures", "internal/migrate/testdata"}
# Nested git repositories (the polyrepo's sub-repositories) are checked as their own roots.


def manifests(repo: pathlib.Path) -> Iterator[pathlib.Path]:
    for current, dirs, files in os.walk(repo):
        relative = pathlib.Path(current).relative_to(repo)
        dirs[:] = [
            d
            for d in dirs
            if d not in SKIP
            and (relative / d).as_posix() not in SKIP_PATHS
            and not (pathlib.Path(current) / d / ".git").exists()
        ]
        if pathlib.Path(current).name == ".ai-rulez" and ".generated-manifest.json" in files:
            yield pathlib.Path(current) / ".generated-manifest.json"


def report(line: str) -> None:
    sys.stdout.write(line + "\n")


def git_lines(repo: pathlib.Path, *args: str, stdin: str = "") -> set[str]:
    result = subprocess.run(["git", "-C", str(repo), *args], input=stdin, capture_output=True, text=True)
    return set(result.stdout.splitlines())


def check(label: str, repo: pathlib.Path) -> bool:
    found = list(manifests(repo))
    if not found:
        report(f"{label:<28} not generated (run mise run setup:ai-rulez)")
        return False
    outputs = []
    for manifest in found:
        base = manifest.parent.parent.relative_to(repo)
        outputs += [(base / f).as_posix() for f in json.loads(manifest.read_text())["files"]]
    tracked = git_lines(repo, "ls-files", "--", *outputs)
    ignored = git_lines(repo, "check-ignore", "--stdin", stdin="\n".join(outputs))
    loose = sorted(set(outputs) - tracked - ignored)
    summary = f"{len(outputs)} outputs: {len(ignored)} ignored, {len(tracked)} tracked"
    if loose:
        report(f"{label:<28} {summary}, {len(loose)} NEITHER: {', '.join(loose[:5])}")
        return False
    report(f"{label:<28} {summary}")
    return True


ok = True
for argument in sys.argv[1:]:
    label, _, path = argument.partition("=")
    ok = check(label, pathlib.Path(path)) and ok
sys.exit(0 if ok else 1)
