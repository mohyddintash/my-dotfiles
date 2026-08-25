#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Placeholder for post-Quattro Quickshell plugins. Omarchy's plugin
# validator rejects symlinks inside a plugin folder, so these get copied,
# never stowed. No-op until quickshell-plugins/ actually has content.
[[ -d quickshell-plugins ]] || exit 0
for plugin in quickshell-plugins/*/; do
  name=$(basename "$plugin")
  mkdir -p ~/.config/omarchy/plugins
  cp -r "$plugin" ~/.config/omarchy/plugins/"$name"
  command -v omarchy-plugin &>/dev/null && omarchy-plugin validate "$name"
done
