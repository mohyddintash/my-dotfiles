#!/bin/bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
#
# WHY THIS IS COPIED, NOT STOWED (unlike every other package in this repo):
#
# `omarchy plugin validate` refuses a plugin folder containing a symlink
# anywhere inside it — confirmed directly, not assumed: `omarchy plugin
# validate ~/.config/omarchy/plugins/mo.lock` failed with "symlinks are not
# allowed inside a plugin folder" when that path was a stow symlink back
# into this repo. Reading the validator's own source
# (/usr/share/omarchy/bin/omarchy-plugin-validate) confirms why:
#
#   # Refuse any symlink anywhere inside the plugin folder. Symlinks could
#   # point a copied plugin back at arbitrary files on disk after it lands
#   # in the trusted plugins directory.
#   link=$(find "$PLUGIN_DIR" -name .git -prune -o -type l -print -quit)
#
# The threat model: everything under ~/.config/omarchy/plugins/<id>/ is
# treated as trusted code the shell loads and executes (QML/JS), including
# plugins installed from arbitrary git repos via `omarchy plugin add`. A
# symlink inside that folder could point outside it — e.g. a malicious
# plugin author ships a manifest.json that's actually a symlink to
# /etc/shadow or another user's files, and whatever reads it (the shell,
# `omarchy plugin update`, a future tool) follows the link instead of
# reading what was actually reviewed before enabling it. The check is a
# blanket rule with no per-plugin trust exception, so it applies to this
# one too even though we wrote it ourselves from Omarchy's own source.
# Same comment block on ~/.config/omarchy/plugins/<id>/Service.qml says why
# THIS content differs from stock, not why it's a copy — that's here.
#
# Every other package in this repo (hyprland, nvim, ghostty, ...) IS a stow
# symlink from ~/dotfiles into $HOME, because Hyprland/apps read their own
# config files directly and don't apply this containment rule. This is the
# one deliberate exception. quickshell-plugins/<id>/ in this repo stays the
# source of truth; re-running this script replaces
# ~/.config/omarchy/plugins/<id>/ wholesale with a fresh real-file copy, so
# it's idempotent (no nesting on a second run) and picks up source edits —
# "edit here, re-run this script" is the update workflow, same role `stow
# -R` plays for every symlinked package.
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
