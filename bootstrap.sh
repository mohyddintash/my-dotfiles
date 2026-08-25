#!/bin/bash
# Bootstrap this dotfiles repo on a fresh Omarchy/Arch machine.
#
# Usage:
#   git clone git@github.com:mohyddintash/my-dotfiles.git ~/dotfiles
#   cd ~/dotfiles && ./bootstrap.sh
#
# Idempotent: safe to re-run. Each step checks before acting.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Packages this repo's stowed configs assume exist. Kept as plain package
# names (no versions) on purpose — Arch is a rolling release and pinning
# individual package versions fights pacman's dependency resolver. Runtime
# versions (node, python, ...) are pinned instead via the stowed mise config
# (mise/.config/mise/config.toml) and applied by `mise install` below.
#
# packages/pacman.txt and packages/aur.txt are `pacman -Qqe` / `pacman -Qqm`
# snapshots of the machine this repo was captured from. Regenerate them with:
#   pacman -Qqe > packages/pacman.txt && pacman -Qqm > packages/aur.txt

# The full set this repo's README documents stowing. kitty and fish are
# included here even though they may not be installed on every machine this
# repo runs on — they're optional alternates (same pattern as the three nvim
# configs below), so their packages get installed but nothing forces you to
# use them.
STOW_PACKAGES=(
  hyprland waybar nvim ghostty kitty alacritty git fish tmux zed
  mako walker btop fastfetch lazygit lazydocker mise imv makima
  swayosd starship bin dev-setup
)

log()  { printf '\033[32m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33mWarning:\033[0m %s\n' "$*" >&2; }

require_yay() {
  if command -v yay &>/dev/null; then
    return
  fi
  log "yay not found, building it (Omarchy ships it by default; this is only for a raw Arch box)"
  sudo pacman -S --needed --noconfirm base-devel git
  local tmp; tmp=$(mktemp -d)
  git clone https://aur.archlinux.org/yay.git "$tmp/yay"
  (cd "$tmp/yay" && makepkg -si --noconfirm)
  rm -rf "$tmp"
}

install_packages() {
  log "Installing packages from packages/pacman.txt + packages/aur.txt"
  if [[ ! -f packages/pacman.txt ]]; then
    warn "packages/pacman.txt missing, skipping package install"
    return
  fi
  yay -S --needed --noconfirm - < packages/pacman.txt
  if [[ -s packages/aur.txt ]]; then
    yay -S --needed --noconfirm - < packages/aur.txt
  fi
}

install_zed() {
  if command -v zed &>/dev/null; then
    log "zed already installed, skipping"
    return
  fi
  log "Installing zed via the official installer (not a pacman/AUR package on this setup)"
  curl -f https://zed.dev/install.sh | sh
}

stow_dotfiles() {
  log "Stowing: ${STOW_PACKAGES[*]}"
  # Fresh installs (or Omarchy defaults) sometimes pre-populate these paths
  # as real files/dirs, which blocks stow from symlinking over them. Only
  # remove if it's not already the correct symlink (keeps this idempotent).
  local -A precreated=(
    [nvim]="$HOME/.config/nvim $HOME/.local/share/nvim $HOME/.cache/nvim"
    [starship]="$HOME/.config/starship.toml"
    [ghostty]="$HOME/.config/ghostty"
    [tmux]="$HOME/.config/tmux/tmux.conf"
  )
  for pkg in "${!precreated[@]}"; do
    for path in ${precreated[$pkg]}; do
      if [[ -e "$path" && ! -L "$path" ]]; then
        log "Removing pre-existing (non-symlink) $path before stowing $pkg"
        rm -rf "$path"
      fi
    done
  done
  stow -t ~ "${STOW_PACKAGES[@]}"
}

apply_runtime_versions() {
  if ! command -v mise &>/dev/null; then
    warn "mise not on PATH yet (shell restart needed?), skipping 'mise install'"
    return
  fi
  log "Installing pinned runtime versions via mise"
  mise install
}

# Hardware-specific quirks for THIS machine (HP Pavilion x360, AMD GPU BIOS
# LTR bug — see dotfiles/README.md "Hardware notes"). Skipped automatically
# on anything else; pass --force-hardware-quirks to apply regardless.
apply_hardware_quirks() {
  local force=${1:-0}
  if [[ $force -ne 1 ]] && ! grep -qi "HP" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
    log "Not an HP machine, skipping HP Pavilion x360-specific quirks (use --force-hardware-quirks to override)"
    return
  fi
  log "Applying HP Pavilion x360 quirks: lid-switch -> lock (not suspend), AMD GPU dpms workaround"
  sudo mkdir -p /etc/systemd/logind.conf.d
  sudo tee /etc/systemd/logind.conf.d/90-lid.conf >/dev/null <<-'EOF'
	[Login]
	HandleLidSwitch=lock
	HandleLidSwitchExternalPower=lock
	EOF
  sudo systemctl restart systemd-logind
  if ! grep -q "amdgpu.aspm=0" /etc/default/limine 2>/dev/null; then
    warn "amdgpu.aspm=0 not found in /etc/default/limine — add it to the kernel cmdline manually, then run 'sudo limine-update'"
  fi
  warn "Also verify hypridle.conf keeps OMARCHY_LOCK_ONLY=true (see README) — never call 'hyprctl dispatch dpms off' on this hardware."
}

# Placeholder for future Quickshell plugins (post-Omarchy-Quattro). Omarchy's
# plugin validator rejects symlinks inside a plugin folder, so these get
# copied, never stowed. No-op until quickshell-plugins/ actually has content.
install_quickshell_plugins() {
  [[ -d quickshell-plugins ]] || return 0
  log "Copying Quickshell plugins (real files, not symlinks — the plugin validator requires this)"
  for plugin in quickshell-plugins/*/; do
    name=$(basename "$plugin")
    mkdir -p ~/.config/omarchy/plugins
    cp -r "$plugin" ~/.config/omarchy/plugins/"$name"
    command -v omarchy-plugin &>/dev/null && omarchy-plugin validate "$name"
  done
}

main() {
  require_yay
  install_packages
  install_zed
  stow_dotfiles
  apply_runtime_versions
  apply_hardware_quirks "$([[ ${1:-} == --force-hardware-quirks ]] && echo 1 || echo 0)"
  install_quickshell_plugins
  log "Done. Log out/reboot for a clean Hyprland session."
}

main "$@"
