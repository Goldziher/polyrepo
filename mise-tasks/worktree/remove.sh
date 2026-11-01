#!/usr/bin/env bash
#MISE description="Remove a clean worktree created by worktree:add"
#USAGE arg "<repo>" help="Registry directory, as listed in repos.txt"
#USAGE arg "<branch>" help="Branch the worktree was created for"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

repo="$usage_repo"
require_registered "$repo"
name=$(worktree_name "$usage_branch")
path="$POLYREPO_ROOT/.worktrees/$repo/$name"
[ -n "$name" ] && [ -d "$path" ] || {
  echo "no worktree at $path" >&2
  exit 1
}
git -C "$POLYREPO_ROOT/$repo" worktree remove "$path"
