#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."

STOW_PACKAGES=(
  hyprland waybar nvim ghostty kitty alacritty git fish tmux zed
  mako walker btop fastfetch lazygit lazydocker mise imv makima
  swayosd starship bin dev-setup
)

# Fresh installs (or Omarchy defaults) sometimes pre-populate these as real
# files/dirs, which blocks stow from symlinking over them. Only remove if
# it's not already the correct symlink (keeps this idempotent).
declare -A precreated=(
  [nvim]="$HOME/.config/nvim $HOME/.local/share/nvim $HOME/.cache/nvim"
  [starship]="$HOME/.config/starship.toml"
  [ghostty]="$HOME/.config/ghostty"
  [tmux]="$HOME/.config/tmux/tmux.conf"
)
for pkg in "${!precreated[@]}"; do
  for path in ${precreated[$pkg]}; do
    [[ -e "$path" && ! -L "$path" ]] && rm -rf "$path"
  done
done

stow -t ~ "${STOW_PACKAGES[@]}"
