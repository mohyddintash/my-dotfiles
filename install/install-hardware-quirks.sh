#!/bin/bash
set -euo pipefail
# HP Pavilion x360 only — AMD GPU BIOS LTR bug (see README "Hardware notes").
# Pass --force to apply regardless of detected hardware.
if [[ "${1:-}" != "--force" ]] && ! grep -qi "HP" /sys/class/dmi/id/sys_vendor 2>/dev/null; then
  echo "Not an HP machine, skipping (pass --force to override)"
  exit 0
fi

sudo mkdir -p /etc/systemd/logind.conf.d
sudo tee /etc/systemd/logind.conf.d/90-lid.conf >/dev/null <<-'EOF'
	[Login]
	HandleLidSwitch=lock
	HandleLidSwitchExternalPower=lock
	EOF
sudo systemctl restart systemd-logind

grep -q "amdgpu.aspm=0" /etc/default/limine 2>/dev/null ||
  echo "Warning: add amdgpu.aspm=0 to /etc/default/limine's kernel cmdline manually, then 'sudo limine-update'" >&2

# Screensaver opens fullscreen terminal windows across every monitor,
# cycling hyprctl focus between them — a burst of multi-output surface
# churn that reproduced the same AMD GPU hang the dpms-off fix (below)
# targets, via a different path (idle-cycle race, not an explicit dpms
# call — see README "Hardware notes"). `omarchy toggle screensaver` is a
# toggle, not a setter, so only flip it if not already off (idempotent).
omarchy-toggle-enabled screensaver-off || omarchy toggle screensaver

echo "Also confirm ~/.config/omarchy/plugins/mo.lock is the active lock service (omarchy-shell shell listPlugins) — never let anything on this hardware call 'hyprctl dispatch dpms off' / hl.dsp.dpms({ action = \"disable\" }). See README 'Hardware notes'."
