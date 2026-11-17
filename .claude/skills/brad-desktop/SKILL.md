---
name: brad-desktop
description: How Brad's customized Omarchy/Hyprland desktop works and how to change it safely — panels and stacks, new-window placement (Cmd+N), stack dots, workspace selector, the dotfiles repo, testing recipes, and crash gotchas. Use alongside the omarchy skill for ANY change to ~/.config/hypr, ~/.config/omarchy, ~/.local/bin/omarchy-* scripts, window placement/stacking/snapping, the bar, or when something in the desktop "is fucked".
---

# Brad's desktop

Omarchy (Hyprland 0.56, Lua config) on an M2 Air, 1280x832 logical (scale 2).
Brad wants macOS-like floating windows, calm visuals, click not hover. Apply
fixes and verify them; don't hand back menus of options.

## Rule zero: track everything in the dotfiles repo

Config is a bare repo at `~/.dotfiles`, work tree `$HOME`. `~/.local/bin/dotfiles`
works exactly like git.

- Before you start: `dotfiles status -s` to see what's uncommitted.
- After every working change: `dotfiles add <files>` (new files need explicit
  add; untracked files are hidden) and `dotfiles commit` with the
  Co-Authored-By trailer. One commit per logical change.
- No remote. Ask before pushing.
- To undo: `dotfiles diff`, `dotfiles checkout -- <file>`, `dotfiles log`.
- This skill lives in the repo too (`~/.claude/skills/brad-desktop/`). Update it
  when the design changes or you learn a new gotcha.

## The model: panels and stacks

Every workspace uses Omarchy's **floating** mode (default in
`~/.local/state/omarchy/workspace-layouts/default.lua`). Windows live only in
nine panels: `full left right top bottom tl tr bl br`. A **stack** is two or
more windows in the same panel. No Hyprland groups or tabs (Brad rejects tabs).

| Piece | Where | What |
|---|---|---|
| `omarchy-snap <panel> [addr]` | ~/.local/bin | place a window; `--frame-of <addr>` names its panel (6px tolerance); `--frame <panel>` prints "x y w h" on focused monitor; ends by calling `panel_open_sync()` |
| `panel-open` rule + `panel_open_sync()` | hypr/bindings.lua | rule gives windows tagged `omarchy-mode-opened` the target frame **from their first frame** (no slide): the empty other half if the focused window is in a half and the other half is empty (`panel_open_target()`), else the focused window's frame. Synced on `window.active`, by omarchy-snap, and by omarchy-new-window |
| `panel-open-nomax` rule | hypr/bindings.lua | `suppress_event = "maximize"` so apps that remember being maximized (Firefox) still land in the panel |
| `omarchy-panel-place <addr>` | ~/.local/bin, run from `window.open` | fallback: after 0.2s snaps the new window to the empty other half, else the previous window's panel (full on empty workspace); must agree with `panel_open_target()`; honours the `$XDG_RUNTIME_DIR/omarchy-place-full` marker |
| Super+T (Cmd+T) | hypr/bindings.lua | sends Ctrl+T (Ctrl+Shift+T in terminals) for a new tab. Replaces Omarchy's float/tile toggle, which tiled windows full-screen on these floating workspaces |
| `omarchy-new-window [--full]` | ~/.local/bin | Super+N (Cmd+N) new window of the focused app, stacked; Super+Shift+N `--full` fills the workspace |
| `omarchy-panel-drop` | ~/.local/bin | Super+drag release picks a panel; dragged to another display it keeps its last panel (from `omarchy-snap --last`, memo in `$XDG_RUNTIME_DIR/omarchy-panels/`) |
| Super+Shift+Ctrl+arrows | hypr/bindings.lua | move window to that display, same panel |
| `omarchy-snap-dir` | ~/.local/bin, Ctrl+Alt+arrows | Up/Down: move to the display that way, same panel (no top/bottom halves; Brad: "we're moving panes around"). Left/Right: snap half; from that half already, carry to the next display's nearer half |
| External display | hypr/monitors.lua | LG UltraFine 5K above the laptop, centered (-640x-1440), 3840x2160 @1.5. Native 5K is 2 tiles; Asahi drives one, so `preferred` loops connect/fail/drop. Each monitor gets its own workspaces 1-10 (DP-1 = ids 11-20) |
| `omarchy-pane-cycle` | ~/.local/bin | Cmd+Tab / Cmd+Shift+Tab: next/previous pane across all displays, wrapping (one pane: rotate its stack). Option+Tab (+Shift) = the pane's stack (Brad's layout) |
| `omarchy-window-cycle`, `omarchy-stack-cycle`, `omarchy-pane-focus` | ~/.local/bin | Option+Tab and Super+` rotate the stack (omarchy-stack-cycle); Super+arrows move focus directionally |
| Stack dots | ~/.config/omarchy/plugins/bradgessler-stacks/ | dots in the bottom band under each stack of 2+; front window brighter; panels covered by a newer window (e.g. a full-screen one) keep dim dots and the covering panel gets a dot in its center (middle of the screen for full); click a dot to bring that window to the front (12pt hit target, hover brightens); polls every 400ms |
| Spotlight (Super+Space menu) | ~/.config/omarchy/plugins/bradgessler.menu/ (clone of omarchy.menu; the shell routes omarchy.menu summons to it) | full-width Go… search on top; menu rows left; StatusGrid.qml column right (Wi-Fi, Bluetooth, Battery, Sound, Weather, Updates) lined up with the rows; clicking a status row closes the menu and summons that Omarchy panel. Hidden for dmenu pickers. Text one step down (title 14, icons 16, rows 44). Keyboard: Right moves into the status column at the same row, Up/Down within it, Enter/Right opens the panel, Left/Esc returns (typing also returns); Enter still drills into submenus. Test keys with `wtype -k Right` (works for layer focus, unlike binds). Scrim stops 32pt short of top and bottom so the black bands stay black. Right after `omarchy restart shell` the menu may not open for a few seconds; retry before assuming it broke. Changes need `omarchy restart shell` |
| `omarchy-bands black\|clear\|toggle` | ~/.local/bin, state in ~/.config/omarchy/bands | clear = top bar (`omarchy-bar background none`) and letterbox band transparent; dots get a dark pill; Spotlight dims the full screen. Black = hardware look; Spotlight's dimming stops at each monitor's reserved top/bottom. Menu: Trigger > Toggle |
| Workspace selector | ~/.config/omarchy/plugins/bradgessler.workspaces/ | numbers only; current one brightest. Clicking the current workspace does nothing (stock widget cycled the layout) |

Omarchy's own floating logic is in `/usr/share/omarchy/default/hypr/workspace-modes.lua`
(read only). It tags windows: `omarchy-floating-workspace`, `omarchy-mode-floated`,
and `omarchy-mode-opened` (from its open rule, so dialogs stay untagged).

## When stacking, dots, or placement break

Check in this order:

1. **Is the workspace still floating?** `ls ~/.local/state/omarchy/workspace-layouts/`.
   A `<n>.lua` saying `scrolling`/`dwindle` means it is tiled and none of the
   above applies. To fix, cycle with `omarchy-hyprland-workspace-layout-toggle`
   while on it, then `hyprctl eval 'o.workspace_mode({ workspace = "N", mode = "floating" })'`.
   A plain `hyprctl reload` did NOT re-float it (2026-11-15).
2. **Does the new window carry `omarchy-mode-opened`?** `hyprctl -j clients | jq '.[] | {class,tags,floating,fullscreen}'`.
   No tag → Omarchy's open rule didn't match (tiled workspace, or an app with its own float rule).
3. **Is it maximized/fullscreen?** `fullscreen != 0` makes panel-place skip it.
4. **Stale rule geometry?** Run `hyprctl repl 'panel_open_sync()'` and retry.

## Testing recipes

Keybind presses can't be faked (`wtype` doesn't trigger binds). Drive things
through Hyprland instead, and **close every test window you open**.

```bash
# Simulate Cmd+N and watch where the new window appears
before=$(hyprctl -j clients | jq -r '.[].address' | sort)
hyprctl dispatch 'hl.dsp.exec_cmd("omarchy-new-window")'
for i in $(seq 1 3000); do new=$(comm -13 <(echo "$before") <(hyprctl -j clients | jq -r '.[].address' | sort)); [[ -n $new ]] && break; done
hyprctl -j clients | jq -c --arg a "$new" '.[]|select(.address==$a)|{at,size}'   # first frame
sleep 1; hyprctl -j clients | jq -c --arg a "$new" '.[]|select(.address==$a)|{at,size}'
hyprctl dispatch "hl.dsp.window.close({ window = \"address:$new\" })"

# See the stack dots / top bar (grim takes logical coords, "x,y WxH")
grim -g "0,800 1280x32" band.png
grim -g "0,0 400x32" bar.png
```

- `hyprctl eval '<lua>'` runs Lua silently; `hyprctl repl '<lua>'` prints the result.
- `hyprctl dispatch` takes Lua: `hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`.
- After any hypr edit: `hyprctl reload && hyprctl configerrors` (empty = good).
- Shell plugins: QML edits hot-reload, but swapping/cloning a plugin or changing
  window geometry needs `omarchy restart shell`.

## Things that crash or bite

- Window-rule `move` is relative to the monitor the window opens on, not global
  coords. `panel_open_sync()` subtracts the active monitor's origin; forget it and
  new panes on the UltraFine (origin -640,-1440) spawn off-screen and fly in.
- `omarchy-new-window` opens a window of the *focused* app; in tests, focus a
  terminal first or you'll spawn Firefox windows.

- **Never resize or move a window in `window.open_early`.** It segfaults Hyprland
  in `Layout::CSpace::resizeTarget` (no layout slot yet), and two crashes drop
  the session into safe mode. Use window rules (size/move) for first-frame
  placement, or `window.open`. Crash reports: `~/.cache/hyprland/hyprlandCrashReport<pid>.txt`.
- Don't leave TEMP/probe code in config. If a session might die, it stays there.
- An open `omarchy-menu` layer blocks focus changes: `omarchy-menu close`.
- `pkill -f` from the Bash tool kills its own shell; use `pkill -x` or hyprctl close.
- `hyprctl clients` order isn't z-order; use `focusHistoryID` (0 = front).
- Never edit `/usr/share/omarchy/`; clone plugins with `omarchy plugin clone`.
- Firefox scale: `layout.css.devPixelsPerPx` 1.75 in user.js (profile + firefox-webapp template) matches his 13" MacBook; needs a Firefox restart.

More history and preferences are in memory: `omarchy-customizations-made.md`
and `user-omarchy-setup-preferences.md` under ~/.claude/projects/-home-bradgessler/memory/.
