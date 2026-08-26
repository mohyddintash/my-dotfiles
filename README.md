# dotfiles

Personal dotfiles for an [Omarchy](https://omarchy.org/) setup on Arch Linux with Hyprland.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each package is a directory that mirrors `$HOME`. Stow creates symlinks from
`~/.config/<pkg>` → `~/dotfiles/<pkg>/.config/<pkg>`.

```
~/dotfiles/
├── hyprland/       → ~/.config/hypr/
├── nvim/           → ~/.config/nvim/        (active nvim config)
├── nvim-lazyvim/   → ~/.config/nvim/        (switch to activate)
├── nvim-nvchad/    → ~/.config/nvim/        (switch to activate)
├── ghostty/        → ~/.config/ghostty/
├── kitty/          → ~/.config/kitty/
├── alacritty/      → ~/.config/alacritty/
├── git/            → ~/.config/git/
├── fish/           → ~/.config/fish/
├── tmux/           → ~/.config/tmux/
├── zed/            → ~/.config/zed/
├── btop/           → ~/.config/btop/
├── fastfetch/      → ~/.config/fastfetch/
├── lazygit/        → ~/.config/lazygit/
├── lazydocker/     → ~/.config/lazydocker/
├── mise/           → ~/.config/mise/
├── imv/            → ~/.config/imv/
├── makima/         → ~/.config/makima/
├── swayosd/        → ~/.config/swayosd/
├── starship/       → ~/.config/starship.toml
├── bin/            → ~/.local/bin/         (tm-sessionizer, dev-setup, ...)
├── dev-setup/      → ~/.config/dev-setup/  (dev-setup's profiles/*.yml)
└── quickshell-plugins/mo.lock/  (NOT stowed — copied to ~/.config/omarchy/plugins/mo.lock
                                   by install/install-quickshell-plugins.sh. Omarchy's plugin
                                   validator rejects symlinks inside a plugin folder, so this
                                   one can't be a stow package. See Hardware notes below.)
```

Omarchy 4 (Quattro) dropped `waybar`, `walker`, and `mako` in favor of its own
Quickshell shell (`omarchy-shell`) — see the `omarchy3-shell-backup` branch
for their configs and install scripts, archived rather than deleted.

## Install on a new machine

```bash
git clone git@github.com:mohyddintash/my-dotfiles.git ~/dotfiles
cd ~/dotfiles
./bootstrap.sh
```

`bootstrap.sh` is a one-line wrapper around `install/install-all.sh`, which
runs every `install/install-<name>.sh` in order — one script per
package/step (`set -e`, so it stops dead at whichever one fails, and
everything before it already succeeded). Run the whole thing, or run any
single `install/install-<x>.sh` on its own. Safe to re-run.

The package scripts cover the real delta beyond what Omarchy already
installs by default — diffed against Omarchy's own
`~/.local/share/omarchy/install/omarchy-{base,other}.packages` manifests, so
this repo isn't duplicating packages the Omarchy installer already gives you
for free. Add a new one the same way: `install/install-<name>.sh` with
`yay -S --needed --noconfirm <name>`, then add a `run install-<name>.sh`
line to `install/install-all.sh`. Related packages that are only ever
installed/removed together get one script (`install-elephant.sh` for
walker's 13-package provider suite, `install-bluez.sh` for
`bluez`+`bluez-utils`, `install-bitwarden.sh` for the app + its CLI).

Note: `kitty` and `fish` are stowed by default but may not be the terminal/shell
actually in use on a given machine — they're optional alternates, same idea
as the three nvim configs below (their packages aren't in `install/` for
that reason; stow their config, install the package only if you switch to
using them).

<details>
<summary>Manual steps (what bootstrap.sh does, if you want to run them by hand)</summary>

```bash
sudo pacman -S stow
cd ~/dotfiles
stow -t ~ hyprland nvim ghostty kitty alacritty git fish tmux zed \
         btop fastfetch lazygit lazydocker mise imv makima \
         swayosd starship bin dev-setup

# quickshell-plugins/ is copied, not stowed (see Structure above):
for plugin in quickshell-plugins/*/; do
  name=$(basename "$plugin")
  cp -r "$plugin" ~/.config/omarchy/plugins/"$name"
done
omarchy-shell shell rescanPlugins
```
</details>

## Switching nvim distros

Three nvim configs are available — only one can be active at a time since they
all symlink to `~/.config/nvim`.

```bash
cd ~/dotfiles

# Switch to LazyVim
stow -D -t ~ nvim
stow -t ~ nvim-lazyvim

# Switch to NvChad
stow -D -t ~ nvim-lazyvim
stow -t ~ nvim-nvchad

# Switch back to main config
stow -D -t ~ nvim-nvchad   # or nvim-lazyvim
stow -t ~ nvim
```

## Adding a new package

```bash
# 1. Create the package structure
mkdir -p ~/dotfiles/<pkg>/.config/<pkg>

# 2. Move the config into it
mv ~/.config/<pkg> ~/dotfiles/<pkg>/.config/

# 3. Stow it
cd ~/dotfiles && stow -t ~ <pkg>

# 4. Commit
git add <pkg> && git commit -m "feat: add <pkg> package"
```

## Important: Omarchy config commands

Omarchy provides commands that affect these configs. Know the difference:

| Command | Effect | Safe? |
|---------|--------|-------|
| `omarchy-restart-<app>` | Reloads the running process | ✅ always safe |
| `omarchy-restart-hyprctl` | Reloads Hyprland config (`hyprctl reload`) | ✅ always safe |
| `omarchy-refresh-<app>` | **Overwrites config with omarchy defaults** (creates `.bak` first) | ⚠️ destructive |

Never run `omarchy-refresh-*` unless you intend to reset that config to omarchy
defaults. If you accidentally do, your config is backed up with a timestamp suffix
(e.g. `config.jsonc.bak.1234567890`) and also recoverable from this git repo.

## After running omarchy update

`omarchy update` may overwrite `hypridle.conf` and `hyprland.conf` via migrations.
It creates a `.bak.<timestamp>` backup first, but you should verify your customisations survived:

```bash
git diff hyprland/.config/hypr/
```

In particular, check that `hypridle.conf` still has `OMARCHY_LOCK_ONLY=true` on the idle lock listener (see hardware notes below). If it's missing, reapply it before the next idle timeout.

## Dev setup auto-launch

At login, a floating popup lets you pick a **profile** (a named app layout —
e.g. work, personal) and launch it into fixed workspaces pinned to each
monitor, or customize select terminals' startup commands for that login
only. Triggered by `exec-once` in `hyprland/.config/hypr/autostart.conf`,
implemented in `bin/.local/bin/dev-setup` and `dev-setup-prompt`, workspace
pinning lives in `hyprland/.config/hypr/monitors.conf`. Profiles are data,
not code — YAML files under `dev-setup/.config/dev-setup/profiles/`; ships
with one (`default.yml`), add more by copying it.

Full details, config schema, and how the profile/Customize flow works:
`bin/.local/bin/README.md` (user-facing) and `bin/.local/bin/AGENTS.md`
(maintenance notes).

## Hardware notes — HP Pavilion x360

### AMD GPU: never use dpms off

`hyprctl dispatch dpms off` causes the display to go permanently black on this machine. Recovery requires a forced reboot.

**Why:** HP BIOS firmware bug — the BIOS never allocates an LTR suspend buffer for the AMD GPU. You will always see this in the boot log:
```
amdgpu: no suspend buffer for LTR; ASPM issues possible after resume
```
This cannot be fixed by any kernel parameter. `amdgpu.aspm=0` is set in `/etc/default/limine` but does not eliminate the underlying BIOS bug — it is kept as extra protection only.

**The fix** is to never call `dpms off`.

**Omarchy 4 (Quattro) and later:** `hypridle` is gone — idle/lock/screensaver is
now handled by the Quickshell `omarchy-shell`, specifically the `omarchy.lock`
service plugin. Its stock `Service.qml` blanks the display 5 seconds after
*any* lock (idle-triggered or manual) by shelling out to
`omarchy-brightness-display off`, which dispatches `hl.dsp.dpms({ action =
"disable" })` — no `shell.json` setting can turn this off, and the
`OMARCHY_LOCK_ONLY` escape hatch from Omarchy 3 has no equivalent here. Fixed
by cloning the plugin (the documented way to customize built-in shell
behavior — see `omarchy plugin clone --help`) and dropping the dpms-off step.
Source lives at `quickshell-plugins/mo.lock/` in this repo — **not stowed**:
`omarchy plugin validate` explicitly rejects a plugin folder containing a
symlink (`omarchy-plugin-validate: symlinks are not allowed inside a plugin
folder`), and a stow-managed folder is exactly that. So
`install/install-quickshell-plugins.sh` plain-copies it into
`~/.config/omarchy/plugins/mo.lock/` instead — real files, no symlink, passes
validation, matches how `omarchy plugin clone` itself lays a plugin down.
Re-running that install script re-copies from the repo (safe/idempotent) and
rescans, so editing the source and re-running is the update workflow.

`Service.qml`'s `blankProcess` in that copy only runs
`omarchy-brightness-keyboard off` (safe) — the `omarchy-brightness-display
off` call is removed, with a comment explaining why. `omarchy plugin clone`
switched the active lock service from `omarchy.lock` to `mo.lock`
automatically; confirm it's still the active one after any `omarchy update`
or `omarchy refresh shell`:

```bash
omarchy-shell shell listPlugins | grep -A2 '"lock"'
# mo.lock should show enabled: true, omarchy.lock should show enabled: false
```

If an Omarchy update ever changes `omarchy.lock`'s `Service.qml` in a way
that matters (new features, security fixes), diff it against this clone —
`omarchy plugin clone` copies the file once, it does not track upstream
changes.

**Omarchy 3.x (pre-Quattro):** the fix lived in `hypridle.conf`, which had to
keep `OMARCHY_LOCK_ONLY=true` on its idle lock listener:

```ini
# hypridle.conf — keep OMARCHY_LOCK_ONLY=true, do NOT change to plain omarchy-system-lock
on-timeout = OMARCHY_LOCK_ONLY=true omarchy-system-lock
```

Kept here for reference only in case of a rollback — `hypridle` is not
installed on Quattro and this file is no longer read.

Whichever mechanism is live, this is the first thing to check if the screen
goes black after idle/lock and won't wake up. Check it after every `omarchy
update`.

### AMD GPU, second trigger: screensaver racing the lock (Quattro)

**In plain terms, for future-us:** think of the screensaver and the lock as
two separate alarm clocks — one set for "start the screensaver" (2.5 min of
no activity), one for "lock the screen" (5 min). In Omarchy 3 these really
were two independent alarms; touching one didn't affect the other. Quattro
rebuilt this as one shared alarm system instead of two, and that created an
edge case: if you nudge the mouse *right* as the screensaver alarm goes off,
the code doesn't fully cancel the countdown — it just says "keep waiting."
So the lock alarm, which should have been reset by that nudge, keeps quietly
ticking in the background. When it finally goes off 5 minutes later, the
lock screen starts appearing — and at that exact same moment, the shared
alarm system gets confused, thinks "we're idle again," and starts the
screensaver a **second time**, from scratch. Now the lock screen is building
itself on both monitors at the same time a fresh screensaver is trying to
open windows on both monitors too — that pile-up of simultaneous screen
activity is what this GPU's firmware bug couldn't survive, even though
nothing explicitly told the screen to power off this time. Fix: turn the
screensaver off entirely, so there's no second thing left to pile onto the
lock. **This is why the screensaver is disabled on this machine** — if you
ever wonder why and are tempted to turn it back on, this is why not to
(until Omarchy fixes the underlying race — see the bug report drafts,
`omarchy-bug-reports.md`, not yet filed as of this writing).

The technical version, for whoever's debugging this later:

The `mo.lock` fix above stops the *explicit* dpms-off call, but the machine
hard-hung again after it was already deployed — a genuinely different
trigger, confirmed from `journalctl -b -1`/`-2`/`-4`, not guessed:

Two earlier locks that day (09:08:50, 18:27:21) completed cleanly
(`process-exit: lock exitCode=0`, `secure=true`) — in both, the screensaver
had already launched and exited *minutes* earlier, no overlap. The crash
(20:07:25) had a different shape: a brief activity blip during the
screensaver's 3-second launch grace window kept the idle cycle alive instead
of cancelling it (`omarchy-shell`'s own idle service logs "screensaver cycle
remains armed" for this case — a real quirk in
`shell/plugins/services/idle/Service.qml`'s `handleActiveSignal()`, not
something in this repo). So when the lock timer fired 150s later,
`lockSystem()` reset `idledThisCycle`, the idle-monitor immediately reported
"idle" again, and a **second, concurrent idle cycle started** — its
screensaver launch (`omarchy-launch-screensaver`, which opens fullscreen
terminal windows on *every* monitor in sequence, moving `hyprctl` focus
between them) landed at nearly the same instant as the lock's own
session-lock surface creation. That's a burst of simultaneous multi-output
surface/modeset activity on both `eDP-1` and `HDMI-A-1` at once — the same
class of GPU power-state churn the dpms-off bug belongs to, just reached via
a different path (an idle-service race, not an explicit dpms dispatch).

**The fix:** disable the screensaver outright — it's cosmetic, and it's the
concrete element adding avoidable GPU-facing multi-output activity to this
cycle. Locking itself is unaffected.

```bash
omarchy-toggle-enabled screensaver-off || omarchy toggle screensaver   # idempotent — it's a toggle, not a setter
```

This persists as a flag file at `~/.local/state/omarchy/toggles/screensaver-off`
— **outside this repo**, so it does NOT survive a fresh install via `stow`.
`install/install-hardware-quirks.sh` applies it (HP-gated, idempotent) so
`bootstrap.sh` covers it on a new machine; if you ever run
`omarchy-toggle-enabled screensaver-off` after a reinstall and get "currently
enabled" back, re-run that script (or the one-liner above).

This is arguably a real Omarchy shell bug independent of this hardware (an
idle cycle re-triggering itself immediately after `lockSystem()`, launching
a second screensaver mid-lock) and could be worth reporting upstream
regardless of whether this specific GPU can tolerate it — see the `omarchy`
skill's `contributing.md` for the reporting flow. Not filed as of this
writing.

### Lid switch

Logind defaults to `HandleLidSwitch=suspend`. A full suspend also triggers the AMD GPU resume bug. If the drop-in `/etc/systemd/logind.conf.d/90-lid.conf` is missing (e.g. after a reinstall), recreate it:

```ini
[Login]
HandleLidSwitch=lock
HandleLidSwitchExternalPower=lock
```

Then restart logind: `sudo systemctl restart systemd-logind`

## Branches

| Branch | Contents |
|--------|----------|
| `master` | Current Omarchy setup — all active configs |
| `old-distro-backup` | Previous distro configs (i3, polybar, wofi, etc.) preserved for reference |
| `omarchy3-shell-backup` | Omarchy 3's native shell configs (`waybar`, `walker`, `mako`) and their install scripts, retired when Quattro replaced them with `omarchy-shell` (Quickshell) |
