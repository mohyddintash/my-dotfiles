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
| `bin` | `~/.local/bin/` | See `bin/.local/bin/AGENTS.md` for the `dev-setup` login-prompt scripts |
| `dev-setup` | `~/.config/dev-setup/` | `profiles/*.yml` — the app-list profiles the `dev-setup`/`dev-setup-prompt` scripts (in `bin`) read; see `bin/.local/bin/AGENTS.md` |
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

## Which hypr files omarchy migrations can overwrite

`omarchy update` runs migrations that write directly through the stow symlinks into the dotfiles repo. These files **can be silently overwritten**:

| File | Risk |
|------|------|
| `hyprland/.config/hypr/hypridle.conf` | Overwritten by migrations; omarchy creates a `.bak.<timestamp>` backup first |
| `hyprland/.config/hypr/hyprland.conf` | Can be updated by migrations |

After any `omarchy update`, always run `git diff hyprland/.config/hypr/` to check for unexpected changes and reapply customisations if needed.

These files are **user-only** — omarchy never overwrites them:

- `monitors.conf`, `bindings.conf`, `input.conf`, `envs.conf`, `looknfeel.conf`, `autostart.conf`
- They are sourced by `hyprland.conf`; omarchy keeps its own defaults in `~/.local/share/omarchy/default/hypr/`

## HP Pavilion x360 — known hardware issues

### AMD GPU dpms hang (display goes black permanently)

`hyprctl dispatch dpms off` causes a hard hang on wake on this machine. The display goes black and cannot be recovered without a forced reboot.

**Root cause:** HP BIOS firmware bug — the BIOS (`FADT`) never allocates an LTR suspend buffer for the AMD GPU. This produces the warning at every boot:
```
amdgpu 0000:01:00.0: no suspend buffer for LTR; ASPM issues possible after resume
```
This warning **cannot be eliminated** — it is a hardware/firmware bug unfixable by kernel parameters. `amdgpu.aspm=0` is present in the kernel cmdline (via `/etc/default/limine`) but does not silence this warning because the BIOS already declares ASPM unsupported at the hardware level (`FADT indicates ASPM is unsupported`). The parameter is kept as a belt-and-suspenders measure but is not the real fix.

**The real fix** is to never call `dpms off` at all. Two layers of protection are in place:

1. **`environment/.config/environment.d/hp-amdgpu-workaround.env`** sets `OMARCHY_LOCK_ONLY=true` for the entire user session via systemd. This is the primary guard — it survives omarchy updates completely because omarchy never touches `environment.d`. Takes effect on next login.

2. **`hypridle.conf`** idle lock listener uses `OMARCHY_LOCK_ONLY=true omarchy-system-lock` explicitly as a secondary/documentation layer.

`OMARCHY_LOCK_ONLY=true` prevents `omarchy-system-lock` from calling `omarchy-brightness-display off` (which would trigger `dpms off`). Even if omarchy update overwrites `hypridle.conf` and removes the explicit flag, the env var from `environment.d` still protects the session.

**Never** add `hyprctl dispatch dpms off` to hypridle listeners or any idle/lock scripts on this machine.

### Lid switch

This machine's logind default (`HandleLidSwitch=suspend`) triggers a full system suspend on lid close. Due to the same AMD GPU / HP BIOS issue, the system may not resume. If the lid is closed accidentally and the system hangs, create `/etc/systemd/logind.conf.d/90-lid.conf` to prevent future occurrences:
```ini
[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=lock
```
Then run `sudo systemctl restart systemd-logind`.

## What NOT to edit

- `~/.local/share/omarchy/` — omarchy source files, managed by omarchy-update
- Do not run `omarchy-refresh-*` commands without user confirmation
