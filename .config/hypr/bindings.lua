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

-- Rectangle.app-style window snapping (Ctrl+Alt, like Rectangle's Ctrl+Option).
o.bind("CTRL + ALT + LEFT", "Snap window left half", "omarchy-snap left")
o.bind("CTRL + ALT + RIGHT", "Snap window right half", "omarchy-snap right")
o.bind("CTRL + ALT + UP", "Snap window top half", "omarchy-snap top")
o.bind("CTRL + ALT + DOWN", "Snap window bottom half", "omarchy-snap bottom")
o.bind("CTRL + ALT + RETURN", "Maximize window", "omarchy-snap full")
o.bind("CTRL + ALT + C", "Center window", "omarchy-snap center")
o.bind("CTRL + ALT + U", "Snap window top left", "omarchy-snap tl")
o.bind("CTRL + ALT + I", "Snap window top right", "omarchy-snap tr")
o.bind("CTRL + ALT + J", "Snap window bottom left", "omarchy-snap bl")
o.bind("CTRL + ALT + K", "Snap window bottom right", "omarchy-snap br")
o.bind("CTRL + ALT + D", "Snap window first third", "omarchy-snap third-left")
o.bind("CTRL + ALT + F", "Snap window center third", "omarchy-snap third-center")
o.bind("CTRL + ALT + G", "Snap window last third", "omarchy-snap third-right")
o.bind("CTRL + ALT + E", "Snap window first two thirds", "omarchy-snap two-thirds-left")
o.bind("CTRL + ALT + T", "Snap window last two thirds", "omarchy-snap two-thirds-right")

-- Windows snapped to the same spot form a stack; Super+` rotates through it,
-- like Cmd+` cycling an app's windows on macOS.
o.bind("SUPER + GRAVE", "Cycle windows stacked here", "omarchy-stack-cycle next")
o.bind("SUPER + SHIFT + GRAVE", "Cycle windows stacked here (reverse)", "omarchy-stack-cycle prev")

-- Dropping a dragged window mostly on top of another snaps it to that window's
-- frame, so the two stack in the same pane. The drag itself is unchanged.
hl.unbind("SUPER + mouse:272")
o.bind_hold("SUPER + mouse:272", "Move window", hl.dsp.window.drag(), "Stack dropped window", "omarchy-stack-join")

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

-- Super+N like Cmd+N: a new window of the focused app.
o.bind("SUPER + N", "New window of the focused app", "omarchy-new-window")
