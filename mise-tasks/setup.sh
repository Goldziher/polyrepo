#!/usr/bin/env bash
#MISE description="First-time setup: clone repos, install hooks, run subrepo setup, generate AI config"
#MISE tools={node = "26.13.0"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

# Every step runs even when an earlier one fails (an inaccessible private repository, one broken
# subrepository setup), so one failure never leaves the rest of the workspace unprovisioned. ~keep
failed=()
for step in setup:clone setup:hooks setup:subrepos setup:ai-rulez; do
  mise run "$step" || failed+=("$step")
done
if [ "${#failed[@]}" -gt 0 ]; then
  echo "setup finished with failures in: ${failed[*]}" >&2
  exit 1
fi
