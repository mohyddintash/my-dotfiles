# CLAUDE.md — dotfiles repo guide for Claude

This is a GNU Stow-managed dotfiles repo for an Omarchy setup on Arch Linux.

## Key facts

- **OS**: Arch Linux
- **Omarchy version**: 4.x (Quattro). Omarchy itself is now a pacman package
  (`omarchy`) living at `/usr/share/omarchy` (`$OMARCHY_PATH`) — `omarchy
  update` upgrades it like any other package. `~/.local/share/omarchy` is
  kept only as a symlink to `/usr/share/omarchy` for anything still using
  the old Omarchy-3 per-user-git-clone path.
- **Desktop**: Hyprland + `omarchy-shell` (a single long-running Quickshell
  process — bar, launcher, notifications, lock screen, idle handling, OSD).
  Omarchy 3's Waybar + Walker + Mako are gone — see "Git branches" below.
- **Hyprland config format**: Lua, not `.conf`. `~/.config/hypr/hyprland.lua`
  is the entrypoint; see "Hyprland config files" below.
- **Dotfiles location**: `~/dotfiles/`
- **Live configs location**: `~/.config/` (symlinked by stow) — with one
  exception, see "quickshell-plugins/" in the Packages table.
- **Stow target**: `~` (home directory), not `~/.config/`

## How stow works here

Each package dir mirrors `$HOME`. For example:
- `~/dotfiles/hyprland/.config/hypr/monitors.lua`
- stows to → `~/.config/hypr/monitors.lua` (via symlink)

Editing files in `~/dotfiles/<pkg>/` is editing the live config — they are the
same file via symlink.

## Safe vs destructive omarchy commands

Always prefer `omarchy restart <x>` to apply config changes. Never run
`omarchy refresh <x>` unless the user explicitly wants to reset to omarchy
defaults — it overwrites the live config after a timestamped backup. Run
`omarchy commands` (or `omarchy restart --help` / `omarchy refresh --help`)
to get the current list rather than trusting this table blindly — Omarchy
adds/renames these between versions and this table already needed
correcting once (Omarchy 3's `omarchy-restart-waybar` etc. no longer exist).

| Safe (use freely) | Destructive (ask user first) |
|-------------------|------------------------------|
| `omarchy restart hyprctl` | `omarchy refresh hyprland` (overwrites all Lua hypr configs) |
| `omarchy restart shell` | `omarchy refresh shell` (resets `shell.json` to defaults) |
| `omarchy restart terminal` | `omarchy refresh config <path>` |
| `omarchy restart <app>` | `omarchy refresh <app>` |

## After editing configs

| Config changed | Command needed |
|---------------|----------------|
| Any `hypr/*.lua` | `hyprctl reload && hyprctl configerrors` (auto-reloads on save; always verify with `configerrors` after) |
| `hypr/hyprsunset.conf` | `omarchy restart hyprsunset` |
| `omarchy/shell.json` or a shell plugin | `omarchy restart shell` (or just save — plugin code and `shell.json` hot-reload) |
| `quickshell-plugins/mo.lock/` (or any `quickshell-plugins/<id>/`) | edit the repo source, then re-run `install/install-quickshell-plugins.sh` — it copies, validates, and rescans. Editing the live `~/.config/omarchy/plugins/<id>/` copy directly works too but won't persist to the repo. |

## Packages in this repo

| Package | Maps to | Notes |
|---------|---------|-------|
| `hyprland` | `~/.config/hypr/` | Note: package name ≠ config dir name. Lua config — see "Hyprland config files" below |
| `nvim` | `~/.config/nvim/` | Active nvim config |
| `nvim-lazyvim` | `~/.config/nvim/` | Inactive — stow swap to use |
| `nvim-nvchad` | `~/.config/nvim/` | Inactive — stow swap to use |
| `starship` | `~/.config/starship.toml` | Single file, not a directory |
| `bin` | `~/.local/bin/` | See `bin/.local/bin/AGENTS.md` for the `dev-setup` login-prompt scripts |
| `dev-setup` | `~/.config/dev-setup/` | `profiles/*.yml` — the app-list profiles the `dev-setup`/`dev-setup-prompt` scripts (in `bin`) read; see `bin/.local/bin/AGENTS.md` |
| all others | `~/.config/<pkg>/` | |

**`quickshell-plugins/<id>/` is NOT a stow package** — it's the one deliberate
exception. `omarchy plugin validate` refuses a plugin folder containing a
symlink anywhere inside it (confirmed against `omarchy-plugin-validate`'s
own source, which mirrors a check the shell's plugin loader itself applies),
so a stow symlink there fails validation. `install/install-quickshell-plugins.sh`
copies it into `~/.config/omarchy/plugins/<id>/` instead — real files, no
symlink. Never `stow` this directory.

Waybar/Walker/Mako packages existed here through Omarchy 3; removed when
Quattro's `omarchy-shell` replaced all three — see "Git branches" below for
where their configs and install scripts went.

## Switching nvim distros

Only one nvim config can be active at a time:
```bash
stow -D -t ~ nvim && stow -t ~ nvim-lazyvim   # switch to lazyvim
stow -D -t ~ nvim-lazyvim && stow -t ~ nvim   # switch back
```

## Git branches

- `master` — current active configs
- `old-distro-backup` — previous distro (i3, polybar, wofi) kept for reference
- `omarchy3-shell-backup` — Omarchy 3's Waybar/Walker/Mako configs and their
  install scripts, retired when Quattro's `omarchy-shell` replaced all three

## Hyprland config files (Lua, post-Quattro)

Omarchy 3's `.conf` files (`hyprland.conf`, `bindings.conf`, `monitors.conf`,
`input.conf`, `looknfeel.conf`, `autostart.conf`, `envs.conf`) are **no
longer read at all** — they still exist on disk in this repo as inert
leftovers from the pre-Quattro setup (kept, not deleted, in case something
still references them; safe to ignore). Hyprland now loads
`~/.config/hypr/hyprland.lua`, which does `require("hypr.monitors")`,
`require("hypr.input")`, `require("hypr.bindings")`, `require("hypr.looknfeel")`,
`require("hypr.autostart")` — edit those `.lua` files, not the `.conf` ones.
`hyprsunset.conf` and `xdph.conf` are the two exceptions still read as plain
`.conf` (separate processes, not part of the Lua config).

The Quattro upgrade's one-time `.conf`→`.lua` migration overwrote
`hyprland.lua`/`monitors.lua`/`input.lua`/`bindings.lua`/`looknfeel.lua`/`autostart.lua`
with fresh Omarchy defaults, discarding whatever had been customized in the
old `.conf` files — nothing ported these automatically. After any future
major Omarchy upgrade, diff `hyprland/.config/hypr/*.lua` against what's in
this repo before assuming customizations survived; going forward within
Quattro, `omarchy update` does not touch these files — only an explicit
`omarchy refresh hyprland` overwrites them (destructive, needs
confirmation).

## HP Pavilion x360 — known hardware issues

### AMD GPU dpms hang (display goes black permanently)

`hyprctl dispatch dpms off` causes a hard hang on wake on this machine. The display goes black and cannot be recovered without a forced reboot.

**Root cause:** HP BIOS firmware bug — the BIOS (`FADT`) never allocates an LTR suspend buffer for the AMD GPU. This produces the warning at every boot:
```
amdgpu 0000:01:00.0: no suspend buffer for LTR; ASPM issues possible after resume
```
This warning **cannot be eliminated** — it is a hardware/firmware bug unfixable by kernel parameters. `amdgpu.aspm=0` is present in the kernel cmdline (via `/etc/default/limine`) but does not silence this warning because the BIOS already declares ASPM unsupported at the hardware level (`FADT indicates ASPM is unsupported`). The parameter is kept as a belt-and-suspenders measure but is not the real fix.

**The real fix** is to never call `dpms off` at all.

**Current fix (Omarchy 4/Quattro):** `hypridle` is not installed on
Quattro — idle/lock/screensaver moved entirely into `omarchy-shell`'s
`omarchy.lock` Quickshell service, which unconditionally calls
`omarchy-brightness-display off` (→ `hl.dsp.dpms({ action = "disable" })`)
5 seconds after ANY lock, with no `shell.json` setting to skip it. Fixed by
cloning `omarchy.lock` to `mo.lock` (`omarchy plugin clone` — the documented
way to override built-in shell plugins) with that one dpms-off line removed.
Source lives at `quickshell-plugins/mo.lock/` in this repo (copied, not
stowed — see Packages table above); full rationale and the exact code diff
are in `README.md`'s Hardware notes section.

**`environment/.config/environment.d/hp-amdgpu-workaround.env` (Omarchy 3
era) no longer does anything under Quattro — confirmed empirically, not
assumed.** It sets `OMARCHY_LOCK_ONLY=true` session-wide, which used to make
`omarchy-system-lock` skip the dpms-off call. Neither the current
`omarchy-system-lock` script nor `omarchy-brightness-display` reference that
env var anymore (read both their sources directly — the "off" case in
`omarchy-brightness-display` dispatches dpms unconditionally). Proof: this
var was active the entire time and the machine still hard-locked from a
dpms-off call during Quattro testing, before the `mo.lock` fix existed. The
file is left in place (harmless, costs nothing) but **do not treat it as a
working safeguard** — the `mo.lock` plugin clone is the only thing
currently preventing this crash. If a future Omarchy version adds a real
`shell.json` knob for this, prefer that over `mo.lock` and delete the clone.

**Never** let anything on this machine call `hyprctl dispatch dpms off` /
`hl.dsp.dpms({ action = "disable" })`, in hypridle listeners (N/A now),
`omarchy-shell` plugins, or any script — check `mo.lock`'s `Service.qml`
first if idle/lock behavior needs changing here.

**A second, distinct trigger exists and hit this machine even with `mo.lock`
already deployed:** the screensaver (`omarchy-launch-screensaver`, which
opens fullscreen terminal windows across every monitor, moving `hyprctl`
focus between them) can end up racing the lock's own session-lock surface
creation, due to a real quirk in `omarchy-shell`'s own idle service
(`handleActiveSignal()` in `shell/plugins/services/idle/Service.qml`): a
brief activity blip during the screensaver's 3-second launch grace window
keeps the idle cycle alive instead of cancelling it, so when the lock timer
fires, `lockSystem()` resets `idledThisCycle` and the idle-monitor
immediately restarts a *second* idle cycle — its screensaver launch lands at
almost the same instant as the lock's surfaces going up on both outputs.
That simultaneous multi-output surface/modeset burst hit this GPU's bug too
— confirmed from `journalctl -b -N` timelines, not guessed (see README
"Hardware notes" for the full before/after log comparison). Fixed by
disabling the screensaver outright (`omarchy toggle screensaver` — cosmetic
feature, locking itself is unaffected):

```bash
omarchy-toggle-enabled screensaver-off || omarchy toggle screensaver
```

This persists in `~/.local/state/omarchy/toggles/screensaver-off` — outside
this repo, so a fresh install needs `install/install-hardware-quirks.sh` (or
the one-liner above) to re-apply it; it won't survive via `stow` alone. If
`mo.lock` alone doesn't seem to be enough on this hardware, check this
setting before assuming the plugin fix regressed — it likely didn't; this is
a different code path.

### Lid switch

This machine's logind default (`HandleLidSwitch=suspend`) triggers a full system suspend on lid close. Due to the same AMD GPU / HP BIOS issue, the system may not resume. If the lid is closed accidentally and the system hangs, create `/etc/systemd/logind.conf.d/90-lid.conf` to prevent future occurrences:
```ini
[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=lock
```
Then run `sudo systemctl restart systemd-logind`.

## What NOT to edit

- `/usr/share/omarchy/` (`$OMARCHY_PATH`) — omarchy's own source, a pacman
  package; managed by `omarchy update`, never by hand. (`~/.local/share/omarchy`
  is just a symlink to this — same rule applies.) Reading it is fine and
  often necessary (e.g. diffing a stock plugin before cloning it).
- Do not run `omarchy refresh <x>` commands without user confirmation
