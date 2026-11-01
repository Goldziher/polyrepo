#!/usr/bin/env bash
#MISE description="Lint root-level polyrepo files with poly"
#MISE tools={"github:Goldziher/poly" = "0.32.1"}
set -euo pipefail
source "$MISE_CONFIG_ROOT/mise-tasks/.lib/polyrepo.sh"

poly lint .
