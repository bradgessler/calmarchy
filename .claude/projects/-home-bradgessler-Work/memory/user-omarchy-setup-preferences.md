---
name: user-omarchy-setup-preferences
description: "Brad runs Omarchy (Arch + Hyprland) on an M2 MacBook Air and wants a calm, macOS-like desktop"
metadata:
  node_type: memory
  type: user
  originSessionId: 88d1e39d-527b-4726-97db-66ce29e5a9ca
  modified: 2026-11-14T12:20:00.000Z
---

Brad uses Omarchy on an Apple M2 MacBook Air (ARM, 2560x1664 at scale 2, Apple multitouch trackpad only).

Strong preferences, stated bluntly:
- Hates bright, high-contrast, "neon" color schemes and loud wallpapers. Likes Monokai (Sublime Text). Wants muted hairline borders and only slight rounding (3pt windows; 6 was too round), round dots fine.
- Wants trackpad behavior like macOS: natural scroll, slow scroll speed, 3/4-finger workspace swipes with inertia, two-finger back/forward in browsers.
- Wants macOS-style floating windows with minimal chrome: no title bars, dock hidden, launches from Super+Space like Spotlight, status icons hidden behind a click-to-open chevron. Uses Rectangle-style snapping, "stacks" of windows in one pane (never tabs), and macOS shortcuts mapped to Super (Cmd+Tab, Cmd+N, Cmd+arrows). Would like a fast Mission Control on 4-finger swipe up (hyprexpo not packaged; building it risks crashing the session, so ask first).
- Mostly dislikes hover-to-reveal UI and wants click to open; the exception is the Firefox URL pill, which comes up on hover (fades, never slides).
- Prefers Firefox over Chromium; wants it ultra minimal: no toolbars, no tabs at all (windows in stacks instead), URL only as a bottom pill. Calls the project "Calmarchy" (github.com/bradgessler/calmarchy); Omarchy's stock UI is "Doritos and Surge".
- Terminal font is Berkeley Mono (licensed copy in ~/.local/share/fonts); UI font is Inter. Brad was enthusiastic about Inter everywhere ("InterOS") and wants all UI fonts to match.
- Gets frustrated quickly; wants fixes applied, not option menus. Rejected a structured multiple-choice question once ("I think you turned off tiling or something"). Prefer a short diagnosis plus a concrete fix over asking.

**How to apply:** default to muted colors and calm visuals, make changes directly and verify with a screenshot, keep explanations short. See [[omarchy-customizations-made]].
