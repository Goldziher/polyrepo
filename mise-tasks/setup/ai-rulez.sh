#!/usr/bin/env bash
#MISE description="Generate AI assistant configuration in the root and recursively in every sub-repository"
#MISE tools={node = "26.13.0"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

# --gitignore keeps each root's managed .gitignore block in step with its outputs. The root sets
# gitignore = false (its .gitignore already ignores every top-level directory), so it is a no-op
# there. ~keep
status=0
if npx -y ai-rulez@latest generate --no-local --gitignore >/dev/null; then
  printf '%-28s generated\n' .
else
  printf '%-28s generate FAILED\n' . >&2
  status=1
fi
# Per repository, so each nested root's patterns land in that repository's .gitignore rather than
# the polyrepo's. plugin/ roots are built by each product's plugin pipeline, and ai-rulez keeps test
# configs under tests/fixtures/ and internal/migrate/testdata/; plain generate would rewrite them. ~keep
while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  [ -f "$repo/.ai-rulez/config.toml" ] || continue
  if (cd "$repo" && npx -y ai-rulez@latest generate --recursive --no-local --gitignore \
    --exclude plugin --exclude tests/fixtures --exclude internal/migrate/testdata >/dev/null); then
    printf '%-28s generated\n' "$dir"
  else
    printf '%-28s generate FAILED\n' "$dir" >&2
    status=1
  fi
done 3<<<"$REGISTRY"
exit "$status"
