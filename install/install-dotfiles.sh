#!/bin/bash
# Stow every package into ~. Never deletes or overwrites anything, so it's
# safe to run any time: already-stowed packages are a no-op.
#
# On a fresh install Omarchy has already written its own real files where
# our symlinks go, and stow refuses to touch them. Packages with no
# conflicts get stowed; for each conflicting file this prints the diff
# command and how to resolve it, then exits non-zero. Resolve, re-run,
# repeat until it's clean. Re-running is the "resume": finished packages
# are skipped by stow itself.
#
# Known gap: when Omarchy pre-made a whole directory (e.g. ~/.config/nvim),
# stow links our files into it, and any extra Omarchy file we don't track
# stays there as a real file without causing a conflict.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STOW_PACKAGES=(
  hyprland nvim ghostty kitty alacritty git fish tmux zed
  btop fastfetch lazygit lazydocker mise imv makima
  swayosd starship bin dev-setup omarchy
)

conflicts=0
for pkg in "${STOW_PACKAGES[@]}"; do
  if out=$(stow -n -d "$DOTFILES" -t "$HOME" "$pkg" 2>&1); then
    stow -d "$DOTFILES" -t "$HOME" "$pkg"
    continue
  fi

  # Conflict lines look like either of:
  #   * cannot stow <src> over existing target <path> since ...
  #   * existing target is not owned by stow: <path>
  mapfile -t targets < <(sed -nE \
    -e 's/.*over existing target (.*) since .*/\1/p' \
    -e 's/.*existing target is not owned by stow: (.*)/\1/p' <<<"$out")

  if ((${#targets[@]} == 0)); then
    printf '\n\033[31m✗ %s\033[0m: stow failed and the reason could not be parsed:\n%s\n' "$pkg" "$out"
    conflicts=$((conflicts + 1))
    continue
  fi

  for rel in "${targets[@]}"; do
    conflicts=$((conflicts + 1))
    printf '\n\033[33m✗ %s\033[0m: ~/%s already exists and is not ours\n' "$pkg" "$rel"
    printf '    yours:    %s\n' "$DOTFILES/$pkg/$rel"
    printf '    existing: %s\n' "$HOME/$rel"
    printf '    compare:  nvim -d %q %q\n' "$DOTFILES/$pkg/$rel" "$HOME/$rel"
  done
done

if ((conflicts > 0)); then
  cat <<EOF

$conflicts conflict(s); everything else is stowed. For each file above:

  1. Compare. In 'nvim -d', the left side is your repo file: put the cursor
     on a hunk and type 'do' to pull in the existing (fresh Omarchy)
     version, or edit by hand. Keep what you want (fixes, new features),
     drop the rest, then save.
  2. Delete the existing file:  rm <existing>
  3. Re-run this script. It picks up where it left off.

Then review and commit what you pulled in:  git -C $DOTFILES diff
EOF
  exit 1
fi

echo "All packages stowed."
