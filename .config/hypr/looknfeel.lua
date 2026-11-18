-- Change the default Omarchy look'n'feel.

-- Opt another application in to Omarchy's standard transparency.
-- Find its class with: hyprctl clients
-- o.transparent_window("my-app")
-- o.transparent_window("my-app", "0.9 0.85") -- Custom active/inactive opacity.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
-- hl.config({
--   general = {
--     -- No gaps between windows or borders.
--     gaps_in = 0,
--     gaps_out = 0,
--     border_size = 0,
--
--     -- Change to niri-like side-scrolling layout.
--     layout = "scrolling",
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- Omarchy disables the workspace animation, which makes trackpad swipes snap
-- with no follow-through. Re-enable it with a gentle ease-out (easeOutCubic,
-- 450ms) for a macOS Spaces-like settle. The first curve, (0.1, 0.9)/(0.2, 1),
-- covered ~90% of the screen in the first instant, which read as far too fast,
-- worst on the 2560pt-wide UltraFine.
hl.curve("swipeOut", { type = "bezier", points = { { 0.33, 1.0 }, { 0.68, 1.0 } } })
hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5, bezier = "swipeOut", style = "slide" })

-- Calm the focused-window border: a thin, muted outline instead of the theme accent.
hl.config({
  general = {
    border_size = 1,
    col = {
      -- 1pt is Hyprland's floor (2 physical px on Retina), so soften it to read as a hairline.
      -- The same faint hairline on every window, just enough to define its
      -- edge (none at all looked weird). Not a focus signal.
      active_border = "rgba(ffffff1f)",
      inactive_border = "rgba(ffffff1f)",
    },
  },
  -- Slight rounding (3pt): just takes the edge off. Brad rejected 6 as too
  -- round; small keeps the 8pt border grab for resizing reaching the corners.
  decoration = {
    rounding = 3,
  },
})

-- No title bars on floating windows. Shadows stay inside the 8pt gap between
-- panes (range 7) so one never falls on another window: faint on inactive
-- windows, darker on the active one (Hyprland has one size for both, so the
-- active one reads "larger" by depth). Omarchy's 16pt shadows smudged the gaps
-- and its floating mode resets this after user config loads, so reapply once
-- every reload settles.
local function no_titlebars()
  hl.config({ plugin = { hyprbars = { enabled = false } } })
  hl.config({ decoration = { shadow = {
    enabled = true, range = 7, render_power = 4, offset = "0 0",
    color = "rgba(00000066)", color_inactive = "rgba(00000026)",
  } } })
  -- No dimming of inactive windows: it shifts their colours (comparing two
  -- photos side by side would be wrong).
  hl.config({ decoration = { dim_inactive = false } })
end
no_titlebars()
hl.on("config.reloaded", no_titlebars)

-- Cursor the size of macOS's default pointer (Omarchy's 24 read a bit big).
-- The env reaches apps started after login; setcursor and gsettings apply now.
hl.env("XCURSOR_SIZE", "20")
hl.env("HYPRCURSOR_SIZE", "20")

-- New panes fade in quickly, already at their panel's size and spot (the
-- panel-open rule sizes them from the first frame), instead of popping in from
-- 87% scale. popin 100% means no scaling, so only the fade shows.
hl.animation({ leaf = "windowsIn", enabled = true, speed = 1.5, bezier = "easeOutQuint", style = "popin 100%" })
hl.animation({ leaf = "fadeIn", enabled = true, speed = 1.5, bezier = "easeOutQuint" })

-- Sharp text in the shell (and other Qt Quick apps): native, hinted glyphs
-- instead of Qt Quick's distance-field text, which looks soft at menu sizes,
-- worst at the UltraFine's 1.5x.
hl.env("QML_DISABLE_DISTANCEFIELD", "1")

-- Swipes scale with the display. Hyprland has one swipe distance (input.lua:
-- 350) and one slide duration (4.5 = 450ms) for every display, so on the
-- 2560pt-wide UltraFine the same finger travel and time cover twice the pixels
-- and feel twice as fast. Scale both by the display's width on a curve (square
-- root of the width ratio to the 1280pt laptop), capped at 1.6x so no display
-- ever needs an impossible swipe. Re-applied whenever the focused display changes.
local function scale_swipes()
  local m = hl.get_active_monitor()
  if not m or not m.width or not m.scale or m.scale == 0 then return end
  local k = math.max(1, math.min(1.6, math.sqrt((m.width / m.scale) / 1280)))
  hl.config({ gestures = { workspace_swipe_distance = math.floor(350 * k + 0.5) } })
  hl.animation({ leaf = "workspaces", enabled = true, speed = 4.5 * k, bezier = "swipeOut", style = "slide" })
end
scale_swipes()
-- The events fire just before the focus change lands, so look a beat later.
for _, event in ipairs({ "config.reloaded", "monitor.focused", "workspace.active" }) do
  hl.on(event, function()
    hl.timer(scale_swipes, { timeout = 30, type = "oneshot" })
  end)
end

-- Easier edge resizing: the grab zone outside each window's edge spans the
-- whole 12pt gap between panes (Omarchy's 8 was hard to hit).
hl.config({ general = { extend_border_grab_area = 12 } })

-- The bar stays on top. Omarchy lets you drag the bar's empty space to another
-- screen edge, which is easy to do by accident without title bars (reaching for
-- the top of a window), and has no setting to lock it. Check every two seconds
-- and put it back.
local function keep_bar_on_top()
  local f = io.open((os.getenv("HOME") or "") .. "/.config/omarchy/shell.json", "r")
  if not f then return end
  local text = f:read("*a") or ""
  f:close()
  local pos = text:match('"bar"%s*:.-"position"%s*:%s*"(%a+)"')
  if pos and pos ~= "top" then hl.exec_cmd("omarchy-bar position top") end
end
hl.timer(keep_bar_on_top, { timeout = 2000, type = "repeat" })
