#!/usr/bin/env bash
#MISE description="Clone all sub-repositories (skips existing)"
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

while read -r dir remote <&3; do
  if [ -d "$POLYREPO_ROOT/$dir" ]; then
    echo "Skipping $dir (already exists)"
  else
    git clone "$remote" "$POLYREPO_ROOT/$dir"
  fi
done 3<<<"$REGISTRY"
