# CLAUDE.md — dotfiles repo guide for Claude

This is a GNU Stow-managed dotfiles repo for an Omarchy setup on Arch Linux.

## Key facts

- **OS**: Arch Linux
- **Desktop**: Omarchy (Hyprland + Waybar + Walker + Mako)
- **Dotfiles location**: `~/dotfiles/`
- **Live configs location**: `~/.config/` (symlinked by stow)
- **Stow target**: `~` (home directory), not `~/.config/`

## How stow works here

Each package dir mirrors `$HOME`. For example:
- `~/dotfiles/waybar/.config/waybar/config.jsonc`
- stows to → `~/.config/waybar/config.jsonc` (via symlink)

Editing files in `~/dotfiles/<pkg>/` is editing the live config — they are the
same file via symlink.

## Safe vs destructive omarchy commands

Always use `omarchy-restart-*` to apply config changes. Never use
`omarchy-refresh-*` unless the user explicitly wants to reset to omarchy defaults.

| Safe (use freely) | Destructive (ask user first) |
|-------------------|------------------------------|
| `omarchy-restart-waybar` | `omarchy-refresh-waybar` |
| `omarchy-restart-hyprctl` | `omarchy-refresh-hyprland` |
| `omarchy-restart-<app>` | `omarchy-refresh-<app>` |

## After editing configs

| Config changed | Command needed |
|---------------|----------------|
| Any `hypr/*.conf` | `omarchy-restart-hyprctl` (or auto-reloads on save) |
| `waybar/config.jsonc` or `waybar/style.css` | `omarchy-restart-waybar` |
| `makima/` | `omarchy-restart-makima` |
| `mako/` | `omarchy-restart-mako` |
| `walker/` | `omarchy-restart-walker` |

## Packages in this repo

| Package | Maps to | Notes |
|---------|---------|-------|
| `hyprland` | `~/.config/hypr/` | Note: package name ≠ config dir name |
| `waybar` | `~/.config/waybar/` | |
| `nvim` | `~/.config/nvim/` | Active nvim config |
| `nvim-lazyvim` | `~/.config/nvim/` | Inactive — stow swap to use |
| `nvim-nvchad` | `~/.config/nvim/` | Inactive — stow swap to use |
| `starship` | `~/.config/starship.toml` | Single file, not a directory |
| all others | `~/.config/<pkg>/` | |

## Switching nvim distros

Only one nvim config can be active at a time:
```bash
stow -D -t ~ nvim && stow -t ~ nvim-lazyvim   # switch to lazyvim
stow -D -t ~ nvim-lazyvim && stow -t ~ nvim   # switch back
```

## Git branches

- `master` — current active configs
- `old-distro-backup` — previous distro (i3, polybar, wofi) kept for reference

## What NOT to edit

- `~/.local/share/omarchy/` — omarchy source files, managed by omarchy-update
- Do not run `omarchy-refresh-*` commands without user confirmation
