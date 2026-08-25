#!/bin/bash
set -euo pipefail
# Must run before install-dotfiles.sh
yay -S --needed --noconfirm stow
