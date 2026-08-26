#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
# Omarchy's plugin validator rejects symlinks inside a plugin folder (see
# `omarchy plugin validate --help`), so these are copied here, never stowed.
# quickshell-plugins/<id>/ in this repo is the source of truth; re-running
# this replaces ~/.config/omarchy/plugins/<id>/ wholesale so it stays
# idempotent (no nesting on a second run) and picks up source edits.
[[ -d quickshell-plugins ]] || exit 0
for plugin in quickshell-plugins/*/; do
  name=$(basename "$plugin")
  dest="$HOME/.config/omarchy/plugins/$name"
  mkdir -p ~/.config/omarchy/plugins
  rm -rf "$dest"
  cp -r "$plugin" "$dest"
  omarchy plugin validate "$dest"
done
command -v omarchy-shell &>/dev/null && omarchy-shell shell rescanPlugins >/dev/null 2>&1 || true
