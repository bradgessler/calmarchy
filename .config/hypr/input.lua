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

-- Keep five workspaces around on every display, like macOS Spaces. Hyprland
-- drops a workspace the moment it is empty, and swipes only move between the
-- workspaces on the display you're on, so with nothing kept there was nowhere
-- to swipe to. Omarchy gives each display a block of ten ids (laptop 1-10,
-- next display 11-20, ...) recorded in ~/.local/state/omarchy/monitor-workspaces;
-- each plugged-in display keeps the first five of its own block, pinned to it.
-- (Unpinned, Hyprland parked the laptop's empty ones on the big display.)
local function keep_workspaces()
  local plugged = {}
  for _, monitor in ipairs(hl.get_monitors() or {}) do
    plugged[monitor.name] = true
  end
  local file = io.open((os.getenv("HOME") or "") .. "/.local/state/omarchy/monitor-workspaces", "r")
  local blocks = {}
  if file then
    for line in file:lines() do
      local block, connector = line:match("^(%d+)\t([^\t]*)\t")
      if block then blocks[tonumber(block)] = connector end
    end
    file:close()
  end
  if not next(blocks) then blocks[0] = "" end
  for block, connector in pairs(blocks) do
    local here = connector == "" or plugged[connector]
    for slot = 1, 5 do
      local rule = { workspace = tostring(block * 10 + slot), persistent = here and true or false }
      if here and connector ~= "" then rule.monitor = connector end
      hl.workspace_rule(rule)
    end
  end
end
keep_workspaces()
for _, event in ipairs({ "monitor.added", "monitor.removed" }) do
  -- After Omarchy has recorded the display's block.
  hl.on(event, function()
    hl.timer(keep_workspaces, { timeout = 500, type = "oneshot" })
  end)
end

-- Scroll whatever is under the pointer, like macOS: the pointer's focus follows
-- the mouse (hover, scroll) while the keyboard stays with the window you last
-- clicked. Omarchy's floating mode sets follow_mouse = 0 (pointer ignored until
-- a click) on load and when moving into a floating workspace, so set it back
-- after each of those.
local function scroll_under_pointer()
  hl.config({ input = { follow_mouse = 2 } })
end
scroll_under_pointer()
for _, event in ipairs({ "config.reloaded", "workspace.active", "monitor.focused" }) do
  hl.on(event, scroll_under_pointer)
end
