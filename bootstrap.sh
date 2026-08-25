#!/bin/bash
# Bootstrap this dotfiles repo on a fresh Omarchy/Arch machine.
#
# Usage:
#   git clone git@github.com:mohyddintash/my-dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./bootstrap.sh
#
# The actual work is one script per package/step in install/ — see
# install/install-all.sh for the order, or run any install/install-<x>.sh
# on its own. This wrapper exists just so the documented entrypoint stays
# `./bootstrap.sh` regardless of how install/ is organized internally.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"
exec ./install/install-all.sh "$@"
