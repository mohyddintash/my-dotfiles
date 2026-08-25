#!/bin/bash
set -euo pipefail
# Must run after install-dotfiles.sh (needs the stowed mise config for its
# pinned versions, e.g. node = "24.11.1").
command -v mise &>/dev/null || { echo "mise not on PATH yet, skipping"; exit 0; }
mise install
