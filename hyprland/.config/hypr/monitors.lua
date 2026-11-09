-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Omarchy Quattro stock default (auto-detect single monitor). Kept for
-- reference/experimentation; superseded below by our fixed two-monitor setup.
-- local omarchy_gdk_scale = 2
-- local omarchy_monitor_scale = "auto"
-- hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- Acer CB342CK 34" ultrawide - smooth 60fps, full ultrawide width. Anchor
-- monitor at the origin; the laptop below is positioned relative to it.
hl.monitor({ output = "HDMI-A-1", mode = "2560x1080@60", position = "0x0", scale = 1.25 })

-- Laptop (LG Display, ~15") - scale 1.5 for comfortable text. Physically
-- sits below and to the right of the ultrawide, but only the laptop's LEFT
-- half is actually under the monitor -- the monitor's bottom-right corner
-- lines up with roughly the middle of the laptop screen, so the mouse
-- should cross screens via the laptop's top-left, not top-right.
-- Hyprland positions monitors by LOGICAL (post-scale) pixels, not raw
-- resolution -- ultrawide logical size is 2560/1.25 x 1080/1.25 =
-- 2048x864, laptop logical size is 1920/1.5 x 1080/1.5 = 1280x720. We want
-- the ultrawide's right edge (x=2048) to land at the laptop's horizontal
-- midpoint (640), so x = 2048 - 640 = 1408; y = 864 places the laptop's
-- top edge flush against the ultrawide's bottom edge.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "1408x864", scale = 1.5 })

-- Workspaces: Omarchy 4.5+ gives every monitor its own workspaces 1-10
-- (default/hypr/monitor-workspaces.lua). Hyprland numbers them in blocks of
-- ten per physical monitor, recorded in ~/.local/state/omarchy/monitor-workspaces:
-- the laptop (eDP-1) owns Hyprland workspaces 1-10, the ultrawide (HDMI-A-1)
-- owns 11-20. Super+N goes to slot N of the focused monitor, and the bar labels
-- each monitor's own workspaces 1-10. Don't pin workspaces here: workspace
-- rules fight that system (doubled numbers in the bar, Super+N pulling
-- workspaces across monitors).
-- The dev-setup profiles (dev-setup/.config/dev-setup/profiles/*.yml) use the
-- Hyprland ids: ultrawide N = 10+N, laptop N = N (see bin/.local/bin/AGENTS.md).

-- New workspaces open on the monitor whose block they belong to. Without this
-- Hyprland creates a workspace on whichever monitor has focus, so dev-setup
-- launching an app "into workspace 13" while the laptop has focus would put
-- the ultrawide's workspace on the laptop. These match Omarchy's blocks above
-- (not persistent, so the bar still shows only what exists); if the blocks in
-- the state file ever change, change these with them.
-- One rule per workspace: a range selector ("r[1-10]") wasn't honoured when
-- launching onto a new workspace.
for id = 1, 10 do
  hl.workspace_rule({ workspace = tostring(id), monitor = "eDP-1" })
  hl.workspace_rule({ workspace = tostring(id + 10), monitor = "HDMI-A-1" })
end
