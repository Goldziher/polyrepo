#!/usr/bin/env bash
#MISE description="Run the setup task in every sub-repository that defines one; reports the ones that fail"
#MISE tools={jq = "1.8.2"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

failed=()
while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  [ -d "$repo" ] || continue
  # Subrepositories inherit this root's tasks, setup included, so only a setup task defined inside
  # the subrepository counts; running the inherited one would recurse. ~keep
  defined_in=$(mise -C "$repo" tasks info setup --json 2>/dev/null | jq -r '.source // empty' || true)
  if [[ "$defined_in" == "$repo"/* ]]; then
    echo "Running setup in $dir..."
    (cd "$repo" && mise run setup) || failed+=("$dir")
  fi
done 3<<<"$REGISTRY"
if [ "${#failed[@]}" -gt 0 ]; then
  echo "setup FAILED in: ${failed[*]}" >&2
  exit 1
fi
