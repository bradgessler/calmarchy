-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
-- hl.config({
--   input = {
--     -- Use multiple keyboard layouts and switch between them with Left Alt + Right Alt.
--     kb_layout = "us,dk,eu",
--     kb_options = "omarchy:shift_caps_compose,grp:alts_toggle",
--
--     -- Use a specific keyboard variant if needed (e.g. intl for international keyboards).
--     kb_variant = "intl",
--
--     -- Change speed of keyboard repeat.
--     repeat_rate = 40,
--     repeat_delay = 250,
--
--     -- Start with numlock on by default.
--     numlock_by_default = true,
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
--       -- Control the speed of your scrolling.
--       scroll_factor = 0.4,
--
--       -- Enable the touchpad while typing.
--       disable_while_typing = false,
--
--       -- Left-click-and-drag with three fingers.
--       drag_3fg = 1,
--     },
--   },
-- })

-- App-specific touchpad scroll speeds.
-- o.window("(Alacritty|kitty)", { scroll_touchpad = 1.5 })
-- o.window("foot", { scroll_touchpad = 2.0 })
-- o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Enable touchpad gestures for changing workspaces.
-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Gestures/
-- hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

-- Enable touchpad gestures for moving focus (helpful on scrolling layout).
-- hl.gesture({ fingers = 3, direction = "left", action = function() hl.dispatch(hl.dsp.focus({ direction = "l" })) end })
-- hl.gesture({ fingers = 3, direction = "right", action = function() hl.dispatch(hl.dsp.focus({ direction = "r" })) end })

-- Natural (Apple-style) scrolling, a bit slower than Omarchy's default of 0.4.
hl.config({
  input = {
    natural_scroll = true,
    touchpad = {
      natural_scroll = true,
      scroll_factor = 0.15,
    },
  },
})

-- macOS-style trackpad gestures.
-- Three- or four-finger horizontal swipe switches workspaces, like Spaces.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })

hl.config({
  gestures = {
    -- Don't spawn empty workspaces when swiping past the last one.
    workspace_swipe_create_new = false,
    -- Trackpad travel for one full workspace; smaller = tracks the finger faster.
    workspace_swipe_distance = 350,
    -- Commit after dragging 30% of the way. Keep the force speed moderate: a very low
    -- value lets the last jitter at finger-lift pick the direction and snap back.
    workspace_swipe_cancel_ratio = 0.3,
    workspace_swipe_min_speed_to_force = 25,
  },
})

-- macOS "show desktop": spread four fingers to slide the windows away and reveal
-- the wallpaper, pinch to bring them back.
hl.gesture({ fingers = 4, direction = "pinchout", action = function() hl.dispatch(hl.dsp.exec_cmd("omarchy-show-desktop show")) end })
hl.gesture({ fingers = 4, direction = "pinchin", action = function() hl.dispatch(hl.dsp.exec_cmd("omarchy-show-desktop hide")) end })

-- Keep five workspaces around like macOS Spaces. Hyprland drops a workspace the
-- moment it is empty, and swipes only move between workspaces that exist, so
-- with everything on workspace 1 there was nowhere to swipe to.
for workspace = 1, 5 do
  hl.workspace_rule({ workspace = tostring(workspace), persistent = true })
end
