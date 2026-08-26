#!/bin/bash
# Run every install-*.sh in this directory, in order. set -e means this
# stops dead at whatever script fails — the log line right before the
# error tells you exactly which one, and everything before it already
# succeeded (each is its own yay invocation, not one giant batch).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

log() { printf '\033[32m==>\033[0m %s\n' "$*"; }

run() {
  log "$1"
  . "./$1"
}

# Prerequisites, in dependency order.
run install-yay.sh
run install-stow.sh
run install-dotfiles.sh

# Everything else — order doesn't matter between these.
run install-antigravity.sh
run install-beekeeper-studio.sh
run install-bitwarden.sh
run install-bluez.sh
run install-efibootmgr.sh
run install-firefox.sh
run install-fuse2.sh
run install-fwupd.sh
run install-ghostty.sh
run install-httrack.sh
run install-intel-ucode.sh
run install-local-by-flywheel.sh
run install-noto-fonts-extra.sh
run install-omarchy-keyring.sh
run install-opencode.sh
run install-qbittorrent.sh
run install-rsync.sh
run install-stripe-cli.sh
run install-telegram-desktop.sh
run install-ttf-cascadia-mono-nerd.sh
run install-visual-studio-code.sh
run install-vivaldi.sh
run install-vulkan-tools.sh
run install-yq.sh
run install-zen-browser.sh
run install-zed.sh

# Needs install-dotfiles.sh done first (reads the stowed mise config).
run install-mise-runtimes.sh

# Hardware-gated, safe no-op on non-matching hardware.
run install-hardware-quirks.sh

# No-op until quickshell-plugins/ has content (post-Quattro).
run install-quickshell-plugins.sh

log "Done. Log out/reboot for a clean Hyprland session."
