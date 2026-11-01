#!/usr/bin/env bash
#MISE description="First-time setup: clone repos, install hooks, run subrepo setup, generate AI config"
#MISE tools={node = "26.13.0"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

mise run setup:clone
mise run setup:hooks
mise run setup:subrepos
mise run setup:ai-rulez
