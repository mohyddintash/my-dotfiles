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

-- Laptop (LG Display, ~15") - scale 1.5 for comfortable text. Sits at the
-- ultrawide's bottom-right: Hyprland positions monitors by LOGICAL
-- (post-scale) pixels, not raw resolution -- ultrawide logical size is
-- 2560/1.25 x 1080/1.25 = 2048x864, laptop logical size is 1920/1.5 x
-- 1080/1.5 = 1280x720, so x = 2048 - 1280 = 768 right-aligns their right
-- edges, y = 864 places the laptop's top edge flush against the
-- ultrawide's bottom edge.
hl.monitor({ output = "eDP-1", mode = "1920x1080@60", position = "768x864", scale = 1.5 })

-- Pin workspaces to monitors so switching workspaces never "steals" a
-- workspace from the other screen. Ultrawide is the main monitor, so it
-- gets more workspaces (1-6); laptop gets the rest (7-0).
-- bin/.local/bin/dev-setup's APPS array depends on this exact split — if
-- monitor names or the pinning change, update both together (see
-- bin/.local/bin/AGENTS.md).
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "2", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "4", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "6", monitor = "HDMI-A-1", persistent = true })
hl.workspace_rule({ workspace = "7", monitor = "eDP-1", default = true, persistent = true })
hl.workspace_rule({ workspace = "8", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "9", monitor = "eDP-1", persistent = true })
hl.workspace_rule({ workspace = "10", monitor = "eDP-1", persistent = true })
