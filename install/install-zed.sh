#!/bin/bash
set -euo pipefail
# Not a pacman/AUR package on this setup — official curl installer instead.
command -v zed &>/dev/null && exit 0
curl -f https://zed.dev/install.sh | sh
