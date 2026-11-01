#!/usr/bin/env bash
#MISE description="Move every repository's version-range pins to the newest allowed release, then regenerate"
#MISE tools={node = "26.13.0"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

status=0
while read -r dir repo <&3; do
  [ -f "$repo/.ai-rulez/config.toml" ] || continue
  if (cd "$repo" && npx -y ai-rulez@latest update); then
    printf '%-28s updated\n' "$dir"
  else
    printf '%-28s update FAILED\n' "$dir" >&2
    status=1
  fi
done 3< <(
  printf '. %s\n' "$MISE_CONFIG_ROOT"
  awk -v root="$POLYREPO_ROOT" '{ print $1, root "/" $1 }' <<<"$REGISTRY"
)
[ "$status" -eq 0 ] || exit "$status"
mise run setup:ai-rulez
