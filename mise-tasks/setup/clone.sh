#!/usr/bin/env bash
#MISE description="Clone all sub-repositories (skips complete clones); reports the ones that fail"
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

# Each clone goes to "<dir>.partial" and is renamed into place only once it completes, so an
# interrupted run never leaves a directory that a later run would mistake for a clone. ~keep
partial=""
# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  [ -z "$partial" ] || rm -rf "$partial"
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

status=0
while read -r dir remote <&3; do
  target="$POLYREPO_ROOT/$dir"
  if [ -d "$target" ]; then
    if is_complete_clone "$target"; then
      printf '%-28s already cloned\n' "$dir"
      continue
    fi
    if [ -n "$(ls -A "$target")" ]; then
      printf '%-28s exists but is not a complete clone; remove it and re-run\n' "$dir" >&2
      status=1
      continue
    fi
    rmdir "$target"
  fi
  partial="$target.partial"
  rm -rf "$partial"
  printf '%-28s cloning...\n' "$dir"
  if git clone --quiet "$remote" "$partial" && mv "$partial" "$target"; then
    printf '%-28s cloned\n' "$dir"
  else
    printf '%-28s clone FAILED (%s)\n' "$dir" "$remote" >&2
    status=1
  fi
  rm -rf "$partial"
  partial=""
done 3<<<"$REGISTRY"
exit "$status"
