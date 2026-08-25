#!/bin/bash
set -euo pipefail
yay -S --needed --noconfirm ghostty
xdg-settings set default-terminal ghostty
