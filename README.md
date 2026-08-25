# dotfiles

Personal dotfiles for an [Omarchy](https://omarchy.org/) setup on Arch Linux with Hyprland.
Managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Structure

Each package is a directory that mirrors `$HOME`. Stow creates symlinks from
`~/.config/<pkg>` → `~/dotfiles/<pkg>/.config/<pkg>`.

```
~/dotfiles/
├── hyprland/       → ~/.config/hypr/
├── waybar/         → ~/.config/waybar/
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
├── mako/           → ~/.config/mako/
├── walker/         → ~/.config/walker/
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
└── dev-setup/      → ~/.config/dev-setup/  (dev-setup's profiles/*.yml)
```

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
stow -t ~ hyprland waybar nvim ghostty kitty alacritty git fish tmux zed \
         mako walker btop fastfetch lazygit lazydocker mise imv makima \
         swayosd starship bin dev-setup
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

**The fix** is to never call `dpms off`. The `hypridle.conf` idle lock listener must keep `OMARCHY_LOCK_ONLY=true`:

```ini
# hypridle.conf — keep OMARCHY_LOCK_ONLY=true, do NOT change to plain omarchy-system-lock
on-timeout = OMARCHY_LOCK_ONLY=true omarchy-system-lock
```

This is the first thing to check if the screen goes black after idle and won't wake up. Check it after every `omarchy update`.

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
