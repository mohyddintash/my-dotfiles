-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- Omarchy Quattro stock example, commented for reference:
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "compose:caps,shift:both_capslock_cancel,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Increase sensitivity for mouse/trackpad (default: 0).
--     sensitivity = 0.35,
--
--     -- Turn off mouse acceleration (default: adaptive).
--     accel_profile = "flat",
--
--     touchpad = {
--       -- Use natural (inverse) scrolling.
--       natural_scroll = true,
--
--       -- Use two-finger clicks for right-click instead of lower-right corner.
--       clickfinger_behavior = true,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

hl.config({
  input = {
    -- Switch between US and Arabic layouts with Left Alt + Right Alt.
    kb_layout = "us,ara",
    kb_options = "compose:caps,grp:alt_shift_toggle",

    -- Change speed of keyboard repeat.
    repeat_rate = 40,
    repeat_delay = 600,

    -- Start with numlock on by default.
    numlock_by_default = true,

    touchpad = {
      -- Control the speed of your scrolling.
      scroll_factor = 0.4,
    },
  },
})

-- App-specific touchpad scroll speeds.
o.window("(Alacritty|kitty|foot)", { scroll_touchpad = 1.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- ─── ELAN Digitizer (Touchscreen + Stylus) ───────────────────────────────────
--
-- The ELAN0732 digitizer exposes 4 input nodes:
--   - elan0732:00-04f3:252e         → finger touch (Touch device)
--   - elan0732:00-04f3:252e-stylus  → stylus (Tablet device)
--   - two UNKNOWN nodes             → phantom pointer events
--
-- The stylus and UNKNOWN nodes are hidden at the kernel level via udev:
--   /etc/udev/rules.d/99-disable-elan-pen.rules
-- This was necessary because Hyprland's `enabled = false` does not work
-- for Tablet-category devices, and the UNKNOWN nodes had no usable name.
--
-- The stylus entry below is kept as defensive redundancy in case the
-- udev rule ever stops matching (e.g. after a kernel update changes the name).

-- Disable finger touchscreen
hl.device({ name = "elan0732:00-04f3:252e", enabled = false })

-- Disable stylus — also hidden by udev rule (see above)
hl.device({ name = "elan0732:00-04f3:252e-stylus", enabled = false })

-- ─── Touchpad ────────────────────────────────────────────────────────────────
-- Previously disabled temporarily while diagnosing the ghost cursor issue.
-- Root cause was the ELAN stylus, not the touchpad. Re-enabled.
hl.device({ name = "etps/2-elantech-touchpad", enabled = true })
