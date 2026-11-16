-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

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

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example replaces the default file manager with Flea.
-- o.rebind("SUPER + SHIFT + F", "File manager", { launch = "flea" })

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, { panel = "omarchy.emojis" })

-- Super+L is Cmd+L in macOS muscle memory (focus the address bar), and Omarchy
-- binds it to cycling the workspace layout, which keeps flipping workspaces into
-- scrolling or floating mode by accident. Super+Alt+L still cycles if wanted.
hl.unbind("SUPER + L")

-- Panels (Ctrl+Alt, like Rectangle's Ctrl+Option): halves, quarters, and full.
o.bind("CTRL + ALT + LEFT", "Snap window left half", "omarchy-snap left")
o.bind("CTRL + ALT + RIGHT", "Snap window right half", "omarchy-snap right")
o.bind("CTRL + ALT + UP", "Snap window top half", "omarchy-snap top")
o.bind("CTRL + ALT + DOWN", "Snap window bottom half", "omarchy-snap bottom")
o.bind("CTRL + ALT + RETURN", "Maximize window", "omarchy-snap full")
o.bind("CTRL + ALT + U", "Snap window top left", "omarchy-snap tl")
o.bind("CTRL + ALT + I", "Snap window top right", "omarchy-snap tr")
o.bind("CTRL + ALT + J", "Snap window bottom left", "omarchy-snap bl")
o.bind("CTRL + ALT + K", "Snap window bottom right", "omarchy-snap br")

-- Windows snapped to the same spot form a stack; Super+` rotates through it,
-- like Cmd+` cycling an app's windows on macOS.
o.bind("SUPER + GRAVE", "Cycle windows stacked here", "omarchy-stack-cycle next")
o.bind("SUPER + SHIFT + GRAVE", "Cycle windows stacked here (reverse)", "omarchy-stack-cycle prev")

-- Windows only live in panels: a dragged window lands in one when released
-- (onto another window = its stack, top edge = full, else the half under the pointer).
hl.unbind("SUPER + mouse:272")
o.bind_hold("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), "Land dropped window in a panel", "omarchy-panel-drop")

-- Super+Tab like Cmd+Tab: rotate the stack under the active window, or cycle
-- the workspace's windows when it isn't stacked. (Was: next/previous workspace.)
o.rebind("SUPER + TAB", "Cycle stack or windows", "omarchy-window-cycle next")
o.rebind("SUPER + SHIFT + TAB", "Cycle stack or windows (reverse)", "omarchy-window-cycle prev")

-- Super+Left/Right move between panes, rolling over to the neighboring workspace
-- past the last pane. Super+Up/Down move between stacked-vertical panes.
-- (Was: Hyprland's directional focus, which ignores stacks and stops at the edge.)
o.rebind("SUPER + LEFT", "Focus pane left (or previous workspace)", "omarchy-pane-focus left")
o.rebind("SUPER + RIGHT", "Focus pane right (or next workspace)", "omarchy-pane-focus right")
o.rebind("SUPER + UP", "Focus pane above", "omarchy-pane-focus up")
o.rebind("SUPER + DOWN", "Focus pane below", "omarchy-pane-focus down")

-- Alt+Tab rotates the stack too (was: focus next window, which ignores stacks).
o.rebind("ALT + TAB", "Cycle stack or windows", "omarchy-window-cycle next")
o.rebind("ALT + SHIFT + TAB", "Cycle stack or windows (reverse)", "omarchy-window-cycle prev")

-- Super+T like Cmd+T: a new tab in the focused app (Ctrl+T; Ctrl+Shift+T in
-- terminals). Was: Omarchy's float/tile toggle, which on these floating
-- workspaces tiled the window full-screen.
local function send_shortcut_once(mods, key)
  hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "down" }))
  hl.timer(function()
    hl.dispatch(hl.dsp.send_key_state({ mods = mods, key = key, state = "up" }))
  end, { timeout = 50, type = "oneshot" })
end
o.rebind("SUPER + T", "New tab", function()
  local window = hl.get_active_window()
  for _, tag in ipairs((window and window.tags) or {}) do
    if tag:gsub("%*$", "") == "terminal" then
      return send_shortcut_once("CTRL SHIFT", "T")
    end
  end
  send_shortcut_once("CTRL", "T")
end)

-- Super+N like Cmd+N: a new window of the focused app.
o.bind("SUPER + N", "New window of the focused app", "omarchy-new-window")
-- Cmd+Shift+N: the same, filling the workspace. (Replaces Omarchy's Editor key.)
o.rebind("SUPER + SHIFT + N", "New full window of the focused app", "omarchy-new-window --full")

-- Every new window opens in the panel of the window you were just in, on top
-- of its stack (full on an empty workspace). Dialogs are left alone.
hl.on("window.open", function(window)
  if window and window.address then
    hl.exec_cmd("omarchy-panel-place " .. window.address)
  end
end)

-- So it appears there instead of sliding over from the middle: a rule keeps
-- the focused window's frame, and windows the floating mode opens take that
-- size and spot from their first frame. omarchy-panel-place still settles any
-- case this misses (empty workspace, a window off the panel grid).
-- omarchy-snap calls panel_open_sync() after it moves a window.
function panel_open_sync()
  local a = hl.get_active_window()
  if not a or not a.floating or (a.fullscreen or 0) ~= 0 then
    hl.window_rule({ name = "panel-open", enabled = false })
    return
  end
  hl.window_rule({
    name = "panel-open",
    enabled = true,
    match = { tag = "omarchy-mode-opened" },
    size = string.format("%d %d", a.size.x, a.size.y),
    move = string.format("%d %d", a.at.x, a.at.y),
  })
end
hl.on("window.active", function() panel_open_sync() end)
-- Apps that remember being maximized (Firefox) would otherwise open
-- maximized and skip the panel.
hl.window_rule({ name = "panel-open-nomax", match = { tag = "omarchy-mode-opened" }, suppress_event = "maximize" })
panel_open_sync()
