#!/usr/bin/env bash
#MISE description="Install poly git hooks in the polyrepo root and every sub-repository that declares them"
#MISE tools={"github:Goldziher/poly" = "0.32.1"}
#MISE depends=["governance:hooks:install"]
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

status=0
while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  if [ ! -f "$repo/poly.toml" ] || ! grep -q '^\[hooks' "$repo/poly.toml"; then
    continue
  fi
  if (cd "$repo" && poly hooks install >/dev/null); then
    printf '%-28s hooks installed\n' "$dir"
  else
    printf '%-28s hooks install FAILED\n' "$dir" >&2
    status=1
  fi
done 3<<<"$REGISTRY"
exit "$status"
