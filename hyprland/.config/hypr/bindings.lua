-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Activity monitor (not one of Quattro's default preinstalled bindings).
o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })

-- Quattro's default binds SUPER+SHIFT+W to Omawrite. We use Typora instead.
hl.unbind("SUPER + SHIFT + W")
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora --enable-wayland-ime")

-- Manual laptop-display kill switch + reload, for when eDP-1 glitches
-- (weird flickering, looks broken) and needs a hard reset. Ported from
-- Omarchy 3, where `hyprctl keyword monitor eDP-1, disable` still worked —
-- Quattro's Lua-parser Hyprland rejects `keyword` entirely ("keyword can't
-- work with non-legacy parsers. Use eval."), so this silently did nothing
-- since the migration. hl.monitor() is the direct Lua-API equivalent (same
-- function monitors.lua itself uses), called in-process instead of shelling
-- out — reload re-enables it with correct resolution/scale from
-- monitors.lua, unaffected by this bug since `hyprctl reload` isn't a
-- `keyword` call.
o.bind("SUPER + SHIFT + CTRL + D", "Disable laptop display", function()
  hl.monitor({ output = "eDP-1", disabled = true })
end)
o.bind("SUPER + SHIFT + CTRL + F", "Reload Hyprland config", "hyprctl reload")
