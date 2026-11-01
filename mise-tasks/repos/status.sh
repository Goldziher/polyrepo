#!/usr/bin/env bash
#MISE description="Show each sub-repository's branch, local changes, upstream drift and worktrees, without fetching"
#MISE quiet=true
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

status=0
while read -r dir _ <&3; do
  repo="$POLYREPO_ROOT/$dir"
  if [ ! -d "$repo/.git" ]; then
    printf '%-28s missing (run mise run setup:clone)\n' "$dir"
    continue
  fi
  branch=$(git -C "$repo" symbolic-ref --short -q HEAD || echo "(detached)")
  changes=$(git -C "$repo" status --porcelain | wc -l | tr -d ' ')
  if git -C "$repo" rev-parse --verify --quiet '@{u}' >/dev/null; then
    read -r ahead behind < <(git -C "$repo" rev-list --left-right --count 'HEAD...@{u}')
    drift="ahead $ahead behind $behind"
  else
    drift="no upstream"
  fi
  worktrees=$(($(git -C "$repo" worktree list --porcelain | grep -c '^worktree ') - 1))
  note=""
  if ! git -C "$POLYREPO_ROOT" check-ignore -q "$dir/"; then
    note=", NOT IGNORED by the polyrepo .gitignore"
    status=1
  fi
  printf '%-28s %-24s %s changed, %s, %s worktree(s)%s\n' "$dir" "$branch" "$changes" "$drift" "$worktrees" "$note"
done 3<<<"$REGISTRY"
exit "$status"
