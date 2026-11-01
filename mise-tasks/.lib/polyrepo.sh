# shellcheck shell=bash
# Sourced by the file tasks. It is not executable and sits in a dot directory, so mise does not list
# it as a task. ~keep

: "${MISE_CONFIG_ROOT:?run this through mise run}"

# The polyrepo root is the main checkout, the parent of this repository's shared git directory. It
# differs from MISE_CONFIG_ROOT when a task runs from a worktree of this repository under
# .worktrees/polyrepo/<name>: subrepositories and .worktrees/ exist only in the main checkout,
# while repos.txt is read from the checkout that runs the task. ~keep
git_common_dir=$(git -C "$MISE_CONFIG_ROOT" rev-parse --path-format=absolute --git-common-dir)
# shellcheck disable=SC2034 # read by the tasks that source this file
POLYREPO_ROOT=$(dirname "$git_common_dir")

# Every subrepository inherits this root's tasks, so `mise run setup` in one that lacks its own
# setup task would run this one across the whole workspace. Refuse unless mise was invoked from
# this repository (or a worktree of it) with no nearer mise config in between. ~keep
refuse_outside_root() {
  echo "${MISE_TASK_NAME:-this task} is a polyrepo-root task; run it from $POLYREPO_ROOT," \
    "or define ${MISE_TASK_NAME:-it} in $1's mise.toml" >&2
  exit 1
}
invoked_from=$(cd "${MISE_ORIGINAL_CWD:-$PWD}" && pwd -P)
config_root=$(cd "$MISE_CONFIG_ROOT" && pwd -P)
invoked_common_dir=$(git -C "$invoked_from" rev-parse --path-format=absolute --git-common-dir 2>/dev/null || true)
if [ "$invoked_common_dir" != "$git_common_dir" ]; then
  refuse_outside_root "$(git -C "$invoked_from" rev-parse --show-toplevel 2>/dev/null || echo "$invoked_from")"
fi
dir=$invoked_from
while [ "$dir" != "$config_root" ] && [ "$dir" != / ]; do
  for config in mise.toml .mise.toml mise.local.toml .config/mise.toml .config/mise/config.toml \
    mise/config.toml .mise/config.toml; do
    [ ! -f "$dir/$config" ] || refuse_outside_root "$dir"
  done
  dir=$(dirname "$dir")
done
REPOS_FILE="$MISE_CONFIG_ROOT/repos.txt"

# "<dir> <remote>" per line, comments and blank lines removed; a malformed line aborts the task.
REGISTRY=$(awk '
  { sub(/#.*/, "") }
  NF == 0 { next }
  NF != 2 { printf "%s:%d: expected <dir> <remote>\n", FILENAME, FNR > "/dev/stderr"; exit 1 }
  { print $1, $2 }
' "$REPOS_FILE")
[ -n "$REGISTRY" ] || {
  echo "no repositories in $REPOS_FILE" >&2
  exit 1
}

# Fail unless $1 is a registry directory.
require_registered() {
  if ! awk -v dir="$1" '$1 == dir { found = 1 } END { exit !found }' <<<"$REGISTRY"; then
    echo "not a registry repository: $1 (see $REPOS_FILE)" >&2
    exit 1
  fi
}

# Worktree directory name for a branch: each character outside A-Za-z0-9_- becomes -.
worktree_name() {
  printf '%s' "$1" | LC_ALL=C sed 's/[^A-Za-z0-9_-]/-/g'
}
