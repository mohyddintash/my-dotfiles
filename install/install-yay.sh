#!/bin/bash
set -euo pipefail
# Only needed on a raw Arch box — Omarchy ships yay by default.
command -v yay &>/dev/null && exit 0
sudo pacman -S --needed --noconfirm base-devel git
tmp=$(mktemp -d)
git clone https://aur.archlinux.org/yay.git "$tmp/yay"
(cd "$tmp/yay" && makepkg -si --noconfirm)
rm -rf "$tmp"
