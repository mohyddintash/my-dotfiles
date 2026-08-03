# AGENTS.md — dev-setup / dev-setup-prompt maintenance notes

Agent-facing notes for maintaining `dev-setup` and `dev-setup-prompt`. See `README.md` in this directory for the user-facing description.

## Dependencies

- `hyprctl` — dispatches each app into a workspace via `[workspace N silent]`, so no window-class match rules are needed.
- `uwsm-app --` — prefix used for every launch, for correct systemd scope tracking (matches the convention already used in `~/dotfiles/hyprland/.config/hypr/bindings.conf`).
- `gum` (`/usr/bin/gum`) — used by `dev-setup-prompt` for the styled confirm box, same tool Omarchy's own `omarchy-update-confirm` uses.
- `omarchy-launch-floating-terminal-with-presentation` — the Omarchy binary that opens `dev-setup-prompt` in a centered floating terminal at login. Do not reimplement this; it already has the correct window rule (`+floating-window` tag on `org.omarchy.terminal`) in `~/.local/share/omarchy/default/hypr/apps/system.conf`.

## Workspace-to-monitor mapping

Defined in `~/dotfiles/hyprland/.config/hypr/monitors.conf` (stowed to `~/.config/hypr/monitors.conf`):

- Ultrawide (`HDMI-A-1`): workspaces 1-6
- Laptop (`eDP-1`): workspaces 7-0

`dev-setup`'s `APPS` array must target workspace numbers consistent with this split, or an app will silently land on the wrong monitor. If the monitor pinning in `monitors.conf` ever changes (e.g. different monitor names after a hardware swap — check with `hyprctl monitors`), update both files together.

## Extending the app list

Each `APPS` entry in `dev-setup` is `"workspace|command"`, split on the first `|`. To add an app:

1. Append a line to the `APPS` array with the target workspace number and full launch command (include `uwsm-app --` prefix for consistency).
2. Update the bullet list in `dev-setup-prompt`'s `gum style` call to match — it's static text, not generated from `APPS`, so it needs a manual edit.
3. Update `README.md`'s description if the change is user-visible.

## Testing changes

- Run `dev-setup` directly in a terminal to launch immediately without the confirm prompt — real apps will open on the real desktop.
- Run `dev-setup-prompt` directly to test the confirm flow without waiting for login.
- After editing `monitors.conf` or `autostart.conf`, validate with `hyprctl reload && hyprctl configerrors`.
- The login popup itself (`exec-once` in `autostart.conf`) only fires on a real login/reboot — `hyprctl reload` does not re-trigger `exec-once` lines.
