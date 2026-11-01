#!/usr/bin/env bash
#MISE description="Fetch every checked-out sub-repository and fast-forward the ones that are only behind"
#MISE quiet=true
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  [ -d "$repo/.git" ] || {
    printf '%-28s missing\n' "$dir"
    continue
  }
  git -C "$repo" fetch --prune --quiet || {
    printf '%-28s fetch failed\n' "$dir"
    continue
  }
  if ! git -C "$repo" rev-parse --verify --quiet '@{u}' >/dev/null; then
    printf '%-28s no upstream\n' "$dir"
    continue
  fi
  read -r ahead behind < <(git -C "$repo" rev-list --left-right --count 'HEAD...@{u}')
  if [ "$behind" -eq 0 ]; then
    printf '%-28s up to date (ahead %s)\n' "$dir" "$ahead"
  elif [ "$ahead" -ne 0 ]; then
    printf '%-28s DIVERGED ahead %s behind %s, not touched\n' "$dir" "$ahead" "$behind"
  elif git -C "$repo" merge --ff-only --quiet '@{u}' 2>/dev/null; then
    printf '%-28s fast-forwarded %s commit(s)\n' "$dir" "$behind"
  else
    printf '%-28s behind %s, fast-forward blocked by local changes\n' "$dir" "$behind"
  fi
done 3<<<"$REGISTRY"
