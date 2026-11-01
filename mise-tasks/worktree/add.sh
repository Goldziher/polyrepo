#!/usr/bin/env bash
#MISE description="Create a worktree at .worktrees/<repo>/<sanitized-branch> under the polyrepo root"
#USAGE arg "<repo>" help="Registry directory, as listed in repos.txt"
#USAGE arg "<branch>" help="Branch to check out; created from the base when it does not exist"
#USAGE flag "--base <ref>" help="Start point for a new branch (default: origin/HEAD)"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

repo="$usage_repo"
branch="$usage_branch"
require_registered "$repo"
src="$POLYREPO_ROOT/$repo"
[ -d "$src/.git" ] || {
  echo "not checked out: $src (run mise run setup:clone)" >&2
  exit 1
}
path="$POLYREPO_ROOT/.worktrees/$repo/$(worktree_name "$branch")"
[ ! -e "$path" ] || {
  echo "already exists: $path" >&2
  exit 1
}
mkdir -p "$(dirname "$path")"
if git -C "$src" show-ref --verify --quiet "refs/heads/$branch"; then
  git -C "$src" worktree add "$path" "$branch"
else
  git -C "$src" fetch --quiet origin
  start="${usage_base:-$(git -C "$src" symbolic-ref --short refs/remotes/origin/HEAD)}"
  git -C "$src" worktree add -b "$branch" "$path" "$start"
fi
echo "$path"
