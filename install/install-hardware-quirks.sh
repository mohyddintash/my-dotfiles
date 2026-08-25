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

echo "Also verify hypridle.conf keeps OMARCHY_LOCK_ONLY=true — never call 'hyprctl dispatch dpms off' on this hardware."
