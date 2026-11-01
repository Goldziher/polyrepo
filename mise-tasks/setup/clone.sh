#!/usr/bin/env bash
#MISE description="Clone all sub-repositories (skips complete clones); reports the ones that fail"
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

# The directory being cloned into. A failed or interrupted clone removes it, so a later run never
# mistakes it for a clone. ~keep
cloning=""
clone_pid=""
# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  # A signal sent only to this script leaves git running; stop it before removing its directory. ~keep
  if [ -n "$clone_pid" ]; then
    kill "$clone_pid" 2>/dev/null || true
    wait "$clone_pid" 2>/dev/null || true
  fi
  [ -z "$cloning" ] || rm -rf "$cloning"
}
trap cleanup EXIT
trap 'exit 130' INT TERM

# True when $1 is the top level of its own repository and HEAD resolves to a commit.
is_complete_clone() {
  local toplevel
  toplevel=$(git -C "$1" rev-parse --show-toplevel 2>/dev/null) || return 1
  [ "$(cd "$toplevel" && pwd -P)" = "$(cd "$1" && pwd -P)" ] || return 1
  git -C "$1" rev-parse --verify --quiet HEAD >/dev/null
}

# A dropped connection aborts a clone midway, so each one is retried from scratch. ~keep
attempts="${SETUP_CLONE_ATTEMPTS:-3}"

status=0
while read -r dir remote <&3; do
  target="$POLYREPO_ROOT/$dir"
  if [ -d "$target" ]; then
    if is_complete_clone "$target"; then
      printf '%-28s already cloned\n' "$dir"
      continue
    fi
    # An empty directory, or one holding only .git (a clone killed before checkout), is a leftover
    # with nothing to lose; anything else may hold work, so it is reported and kept. ~keep
    leftover=$(ls -A "$target")
    if [ -n "$leftover" ] && [ "$leftover" != .git ]; then
      printf '%-28s exists but is not a complete clone; remove it and re-run\n' "$dir" >&2
      status=1
      continue
    fi
    rm -rf "$target"
  fi
  cloning="$target"
  cloned=false
  for attempt in $(seq 1 "$attempts"); do
    rm -rf "$target"
    printf '%-28s cloning (attempt %d/%d)...\n' "$dir" "$attempt" "$attempts"
    # mise may pipe task output, which silences git's progress; force it so slow clones stay visible. ~keep
    git clone --progress "$remote" "$target" &
    clone_pid=$!
    if wait "$clone_pid"; then
      clone_pid=""
      cloned=true
      break
    fi
    clone_pid=""
    [ "$attempt" -eq "$attempts" ] || sleep $((attempt * 5))
  done
  cloning=""
  if "$cloned"; then
    printf '%-28s cloned\n' "$dir"
  else
    printf '%-28s clone FAILED (%s)\n' "$dir" "$remote" >&2
    rm -rf "$target"
    status=1
  fi
done 3<<<"$REGISTRY"
exit "$status"
