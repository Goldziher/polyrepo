#!/usr/bin/env bash
#MISE description="Check generated AI configuration is current and that every output is either tracked or gitignored"
#MISE tools={node = "26.13.0", python = "3.15.2"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

status=0
roots=(".=$MISE_CONFIG_ROOT")
if ! npx -y ai-rulez@latest generate --check --no-local >/dev/null 2>&1; then
  printf '%-28s STALE (run mise run setup:ai-rulez)\n' . >&2
  status=1
fi
while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  [ -f "$repo/.ai-rulez/config.toml" ] || continue
  roots+=("$dir=$repo")
  if ! (cd "$repo" && npx -y ai-rulez@latest generate --check --recursive --no-local \
    --exclude plugin --exclude tests/fixtures --exclude internal/migrate/testdata >/dev/null 2>&1); then
    printf '%-28s STALE (run mise run setup:ai-rulez)\n' "$dir" >&2
    status=1
  fi
done 3<<<"$REGISTRY"
python3 "$MISE_CONFIG_ROOT/mise-tasks/.lib/check_generated.py" "${roots[@]}" || status=1
exit "$status"
