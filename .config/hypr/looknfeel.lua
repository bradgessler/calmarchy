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
      -- Neutral hairlines (the beige 8a8672 read as a muddy rim).
      active_border = "rgba(ffffff2e)",
      inactive_border = "rgba(ffffff14)",
    },
  },
  -- Slight rounding (3pt): just takes the edge off. Brad rejected 6 as too
  -- round; small keeps the 8pt border grab for resizing reaching the corners.
  decoration = {
    rounding = 3,
  },
})

-- No title bars on floating windows, and a shadow only on the active one (like
-- macOS's focused window): small, soft, no offset. Every window having Omarchy's
-- 16pt shadow overlapped into a grey smudge in the 8pt gaps. Omarchy's floating
-- mode resets both after user config loads, so reapply once every reload settles.
local function no_titlebars()
  hl.config({ plugin = { hyprbars = { enabled = false } } })
  hl.config({ decoration = { shadow = {
    enabled = true, range = 14, render_power = 3, offset = "0 3",
    color = "rgba(00000059)", color_inactive = "rgba(00000000)",
  } } })
  -- The active window reads as lit: the others dim a touch.
  hl.config({ decoration = { dim_inactive = true, dim_strength = 0.1 } })
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
