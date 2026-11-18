---
name: calmarchy
description: How Calmarchy works (Brad's calm, Mac-like layer on Omarchy, github.com/bradgessler/calmarchy) and how to change it safely — panes and stacks, new-window placement, stack dots, Spotlight (Cmd+Space) and the per-app Cmd+K menu, the toolbar-free Firefox, multiple displays, the dotfiles repo, testing recipes, and crash gotchas. Use alongside the omarchy skill for ANY change to ~/.config/hypr, ~/.config/omarchy, ~/.local/bin/omarchy-* scripts, Firefox's userChrome/user.js, window placement, the bar, or when something in the desktop "is fucked".
---

# Calmarchy

A calm, Mac-like layer on Omarchy (Hyprland 0.56, Lua config), on an M2 Air
(1280x832 logical, scale 2) plus sometimes an LG UltraFine 5K. Not a fork: config
files, scripts and shell plugins over a stock Omarchy install. Brad wants calm
visuals, no tabs, macOS habits, and fixes applied and verified rather than menus
of options. Read the memory notes first (see bottom).

## Rule zero: the repo

Config is a bare repo at `~/.dotfiles`, work tree `$HOME`, remote
`github.com/bradgessler/calmarchy` (public). `~/.local/bin/dotfiles` works like git.

- Before you start: `dotfiles status -s`.
- After every working change: `dotfiles add <new files>` (untracked files are
  hidden), `dotfiles commit` with the Co-Authored-By trailer, then
  `dotfiles push`. One commit per logical change.
- Keep `~/.github/README.md` (the GitHub page, with screenshots in
  `~/.github/screenshots/`) and `~/.local/bin/omarchy-dotfiles-setup` (what a
  fresh clone needs beyond files) in step with features.
- This skill and the memory notes are in the repo too; update them when the
  design changes or you learn a gotcha.
- Never put secrets, Brad's email, or his Wi-Fi name in the repo or screenshots.

## Panes and stacks

Every workspace is Omarchy **floating** mode (default in
`~/.local/state/omarchy/workspace-layouts/default.lua`). Windows live in nine
panels per display: `full left right top bottom tl tr bl br`. A **stack** is
windows in the same panel. No tabs, no Hyprland groups.

| Piece | Where | What |
|---|---|---|
| `omarchy-snap <panel> [addr]` | ~/.local/bin | place a window. `--frame-of <addr>` names its panel (6px tolerance), `--frame <panel>` / `--frame-on <panel> <monitor-id>` print "x y w h", `--last <addr>` the panel it was last snapped to (memo in `$XDG_RUNTIME_DIR/omarchy-panels/`). Calls `panel_open_sync()` |
| `panel-open` rule, `panel_open_sync()`, `panel_open_target()` | hypr/bindings.lua | gives windows tagged `omarchy-mode-opened` their frame **from the first frame** (they fade in in place): the empty other half if the focused window is in a half and the other half is empty, else the focused window's frame. Rule `move` is monitor-relative |
| `omarchy-panel-place <addr>` | ~/.local/bin, from `window.open` | settles new windows after 0.2s with the same logic; honours `$XDG_RUNTIME_DIR/omarchy-place-full` (Cmd+Shift+N) and `omarchy-place-stack` (Cmd+T in Firefox) markers |
| `omarchy-new-window [--full\|--stack]` | ~/.local/bin | Cmd+N new window of the focused app; `--full` fills the workspace; `--stack` always on the focused stack |
| Cmd+T | hypr/bindings.lua | Firefox: `omarchy-new-window --stack` (tabs are off). Other apps: Ctrl+T (Ctrl+Shift+T in terminals) |
| `omarchy-pane-cycle` | ~/.local/bin | Cmd+Tab / Cmd+Shift+Tab: next/previous pane on all displays, wrapping; one pane = rotate its stack |
| `omarchy-stack-cycle` | ~/.local/bin | Option+Tab (+Shift) and Cmd+`: the pane's stack |
| `omarchy-pane-focus` | ~/.local/bin | Cmd+arrows: pane that way; past the edge, workspace ±1 within the display's block |
| `omarchy-snap-dir` | ~/.local/bin | Ctrl+Option+Left/Right snap halves (again = next display's nearer half); Up/Down only move to the display that way, same panel (no top/bottom halves) |
| `omarchy-panel-drop` | ~/.local/bin | Cmd+drag release: onto a window = its stack; to another display = same panel; else half under pointer, top edge = full |
| `omarchy-window-to-next-display` | ~/.local/bin | used by the Cmd+K pane menu |
| Stack indicators | plugins/bradgessler-stacks/ (no bottom band: the letterbox plugin is disabled in shell.json, nothing reserved at the bottom, so panes get the same 12pt gap on every side; the strip is that 12pt margin. The gap lives in three places that must agree: omarchy-snap `gap`, bindings.lua `PANEL_GAP`, stacks plugin `gap`) | 14x2pt bright bars (front 0.7 at rest, 1.0 on switch; others 0.32); during a trackpad swipe the leaving/arriving workspaces' indicators fade with the fingers (calmarchy-swipe-progress: `libinput debug-events` on the touchpad, accelerated dx / (350·k); needs libinput-tools and the touchpad-only udev rule in ~/.local/share/calmarchy/70-calmarchy-touchpad.rules installed to /etc/udev/rules.d), finishing over the rest of the slide on release; otherwise crossfade over 350ms on workspace switch (all of a display's stacks kept in a keyed ScriptModel, rows start at opacity 0 and bind after creation; Hyprland gives no swipe progress, so it follows the switch, not the finger) in the bottom margin; click target 18pt x the full 12pt gap. Centred in the full gap from window edge to screen edge (`anchors.verticalCenterOffset: 0`; measured 4pt above, 5pt below). Brad reads the shadow as part of the gap, NOT the window: pushing bars down below the shadow looked wrong to him ("bump up means up"). Validate by measuring, not eyeballing: grim the margin at 2x and print a brightness profile down a column through the bar (see Testing) under each stack of 2+ (no backdrop pill; dots, a 10pt band and a pill were tried), faint at rest (front 0.4, others 0.16); on any switch the new front dot fades up to 0.9 for 1.6s then settles; hovering the band lifts the others to 0.3; panels covered by a newer window keep dim dots and the covering one gets a center dot; click = bring to front |
| Workspaces | hypr/input.lua `keep_workspaces()` | five persistent workspaces per display, pinned to it (Omarchy gives each display ids in blocks of ten: laptop 1-10, next 11-20) |

## Menus

| Piece | Where | What |
|---|---|---|
| Spotlight, Cmd+Space | plugins/bradgessler.menu/ (clone of omarchy.menu; the shell routes omarchy.menu summons to it) | the **system** menu: Go… search, rows left, `StatusGrid.qml` column right (Wi-Fi, Bluetooth, Power, Sound, Weather, Updates). Typed URL → first row opens it; other text → web search row. App rows run `omarchy-focus-app <desktop-id>` first: focus the app's most recent window **on a visible workspace** (matched by StartupWMClass/id/exe class; web launchers by `X-Calmarchy-Title=<regex>` in their .desktop), else exit 1 → normal launch here (Brad: don't pull him to another workspace). Hides the Cmd+K menus from its list and search (`paneMenuIds`) |
| Cmd+K | `omarchy-pane-menu` → summon with `{menu, anchor}` | the **app in front**: card centered over the focused pane, only that pane dims, no status column, fuzzy search (subsequence fallback in `MenuModel.matchesQuery`). Menus live in `~/.config/omarchy/extensions/omarchy-menu.jsonc`: `app-<class lowercase>` per app (now `app-firefox`, `app-signal`), picked automatically by `omarchy-pane-menu`, and `pane` (pane moves) for everything else. Each app menu ends with the pane moves. Rows press the app's own shortcuts via `omarchy-send-shortcut`. Apps' own menu bars get hidden. Signal: only its in-app switch works (Settings → General → Hide menu bar, next to the login/tray options); it overrides `autoHideMenuBar` in ~/.config/Signal/ephemeral.json at every start. There's no generic way to read an app's menus on Wayland, so each app's menu is written by hand. Don't use a bare class as the id (`firefox` collides with the app entry) |
| `omarchy-send-shortcut "MODS" KEY` | ~/.local/bin | how app-menu rows press the app's own shortcut after the menu hands focus back |
| `omarchy-bands black\|clear` | ~/.local/bin, state ~/.config/omarchy/bands | black: 32pt bar (26 without a notch) + the 12pt top gap. Clear: the bar is all there is above the windows (top gap 0): 24pt where there is no notch (6pt above the 11.5pt contents, 6 below; Brad wanted it thin, not the 12pt gap on each side) and 32 on the laptop, because windows must not start under the notch. Sizes via notch-height / size-horizontal in shell.toml.tpl. Frames read the mode in omarchy-snap, bindings.lua `top_gap()` and the stacks plugin; the script re-snaps every window. Currently clear |

## Firefox

Files: `~/.config/mozilla/firefox/fo6dm8yb.default-release/{user.js,chrome/userChrome.css,chrome/userContent.css}`,
mirrored in `~/.config/omarchy/firefox-webapp/`. Theme colours come from
`~/.config/omarchy/themed/firefox.css.tpl` (`omarchy-theme-refresh`).
DuckDuckGo default and uBlock Origin Lite are force-installed through
`/etc/firefox/policies/policies.json` (pkexec; Adaptive Tab Bar Colour is set to
`blocked`). All of it needs a Firefox restart (`about:profiles` → Restart normally
keeps tabs; quitting doesn't restore them).

- Web apps (X) are plain windows of the main Firefox (`firefox --new-window <url>` in the .desktop), not separate profiles: the per-site profile (`omarchy-firefox-webapp`) lost X's login cookie on close and has no 1Password. Desktop `Exec=` can't contain `$HOME` (quickshell rejects it).
- No toolbars, no tabs (prefs open windows instead), no link previews, no
  suggestions list (inline autofill only), blank new tabs, no Mozilla data notice.
- The address is a pill centered at the bottom over the page: full for 3s after
  each load, then faint (0.22, never gone, anti-spoofing), full on hover, full
  with a warm border on insecure pages. `userContent.css` adds 64px after each
  page so scrolling clears it. Firefox can't blur web content behind chrome.
- Brad rejected, in order: page-colour tint ("looks like assholes"), a top
  overlay/autohide bar, a click-through pill, a full-width address, slide-in.

## Testing

- **Never send synthetic keystrokes (wtype, send_key_state) while Brad is
  working**: they land in his focused window. Don't pop menus on his screen to
  test without a reason; ask or let him try.
- Stage UI on the laptop's empty workspace 3 with throwaway windows and a
  throwaway Firefox profile (copy user.js + chrome/ into a scratch dir, run
  `firefox --new-instance --profile <dir> <url>`), refocus Brad's window right
  away, close everything after. Park the pointer on the other display before
  `grim`; focus changes warp it.
- Visual alignment: measure it. `grim -g "0,812 1280x20" -s 2 m.png`, then read a column of `magick m.png -colorspace Gray -depth 8 gray:-` bytes through the element and one beside it to find where the window edge, shadow, element and screen edge actually are. Brad notices half-point misalignment.
- Cursor warps don't trigger :hover in Firefox; verify hover states by forcing
  them in the throwaway profile's CSS.
- `hyprctl eval` runs Lua silently, `hyprctl repl` prints. `hyprctl dispatch`
  takes Lua. After hypr edits: `hyprctl reload && hyprctl configerrors`.
- Plugin QML changes need `omarchy restart shell`; the menu may not open for a
  few seconds after, so retry.
- `omarchy-new-window` opens a window of the *focused* app; focus a terminal first.

## Things that crash or bite

- Swipes scale per display: `scale_swipes()` in looknfeel.lua sets swipe distance 350·k and the workspaces slide 4.5·k, k = sqrt(width/1280) capped 1.0–1.6 (laptop 350/450ms, UltraFine 495/636ms), re-applied 30ms after monitor.focused / workspace.active (events fire before focus lands). Hyprland has no per-monitor setting or swipe-progress hook.

- Text replacements: espanso 2.4.1 built from source (the AUR recipe's cargo-make task is gone; build with `cargo build --release --no-default-features --features wayland,modulo,vendored-tls -p espanso`), installed at /usr/local/bin/espanso with `cap_dac_override+p`, user service via `espanso service register`. Rules in ~/.config/espanso/match/. It reads the real keyboard (evdev), so `wtype` can't test it.

- Scrolling goes to the window under the pointer: `follow_mouse = 2` (pointer follows the mouse, keyboard focus on click), reapplied in input.lua on load, config.reloaded, workspace.active and monitor.focused, because Omarchy's floating mode forces 0.

- **Never resize or move a window in `window.open_early`**: it segfaults Hyprland
  (`Layout::CSpace::resizeTarget`); two crashes drop the session into safe mode.
- Window-rule `move` is relative to the monitor; subtract its origin.
- An open `omarchy-menu` layer blocks focus changes: `omarchy-menu close`.
- `pkill -f` from the Bash tool kills its own shell; use `pkill -x` or hyprctl close.
- `hyprctl clients` order isn't z-order; use `focusHistoryID` (0 = front).
- Never edit `/usr/share/omarchy/`; clone plugins with `omarchy plugin clone`.
- If a workspace turns tiled (`~/.local/state/omarchy/workspace-layouts/<n>.lua`
  says scrolling/dwindle), toggle it with `omarchy-hyprland-workspace-layout-toggle`
  then `hyprctl eval 'o.workspace_mode({ workspace = "N", mode = "floating" })'`.
- The UltraFine runs 3840x2160 @1.5 in `monitors.lua`: native 5K is two tiles and
  Asahi drives one. Its USB (brightness, camera) needs Thunderbolt PCIe
  tunnelling, which m1n1/kernel don't set up ("PCIe-C is not initialized"); no
  brightness control from Linux. Brad has no macOS; don't suggest it.
- Touch ID enrollment fails in the experimental SEP driver ("capture ended
  without a frame"); password works.

## Memory

Preferences and history: `~/.claude/projects/-home-bradgessler-Work/memory/`
(`user-omarchy-setup-preferences.md`, `omarchy-customizations-made.md`,
`no-synthetic-typing-while-user-active.md`), tracked in the repo.
