-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

-- Monitor scale is Hyprland's scale for the output. It sizes everything
-- Wayland-native, accepts fractions (1.6, 1.75), and applies immediately.
-- "auto" lets Hyprland pick per display.
local omarchy_monitor_scale = "auto"
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })
hl.monitor({ output = "eDP-1", mode = "preferred", position = "0x0", scale = 2 })

-- LG UltraFine 5K, sitting above the laptop, centered. Its native 5120x2880
-- is two tiles and Asahi's display driver only drives one, so Hyprland's
-- "preferred" mode fails and the display drops and reconnects in a loop.
-- 3840x2160 is a single stream; scale 1.5 makes it "look like" 2560x1440,
-- the macOS default for this panel. Centered: x = (1280 - 2560) / 2.
-- Text size vs the laptop: the laptop is ~112 points/inch, this ~109 at 1.5,
-- so text is ~3% larger here. An exact match needs 1.454, which Hyprland
-- rejects (scale must be n/120 and give whole pixels); 1.333 is 8% too small.
hl.monitor({ output = "desc:LG Electronics LG UltraFine 010NTTQCT641", mode = "3840x2160@60", position = "-640x-1440", scale = 1.5 })

-- Configure a specific monitor.
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })

-- GDK scale is GDK_SCALE, the factor GTK draws its own UI at. It's what
-- sizes X11/XWayland windows, which Omarchy leaves unscaled so they stay
-- crisp instead of being stretched by the compositor. GTK only honors whole
-- numbers, so use the nearest integer to the monitor scale, and restart an
-- app for a change to reach it.
local omarchy_gdk_scale = 2
hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
