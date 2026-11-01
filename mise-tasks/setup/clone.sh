#!/usr/bin/env bash
#MISE description="Clone all sub-repositories (skips existing); reports the ones that fail"
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

status=0
while read -r dir remote <&3; do
  if [ -d "$POLYREPO_ROOT/$dir" ]; then
    printf '%-28s already cloned\n' "$dir"
  elif git clone --quiet "$remote" "$POLYREPO_ROOT/$dir"; then
    printf '%-28s cloned\n' "$dir"
  else
    printf '%-28s clone FAILED (%s)\n' "$dir" "$remote" >&2
    status=1
  fi
done 3<<<"$REGISTRY"
exit "$status"
