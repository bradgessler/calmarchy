import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io
import qs.Commons

// Windows snapped into the same omarchy-snap panel form a stack. Each stack of
// two or more gets a row of dots in the bottom band, centered under it; the
// front window's dot is brighter. When a window (usually a full-screen one)
// covers other panels, those keep dim dots and the covering one gets a dot in
// its center, so every hidden window is one click away. Windows torn off into
// loose spots get no dot. Super+Tab / Alt+Tab rotate a stack.
Item {
  id: root

  property var shell: null

  // With clear bands (omarchy-bands clear) the dots sit on the wallpaper, so
  // each row gets a soft dark pill behind it, like an iOS page indicator.
  FileView {
    id: bandsFile
    path: Quickshell.env("HOME") + "/.config/omarchy/bands"
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
  }
  readonly property bool clearBands: bandsFile.loaded && bandsFile.text().trim() === "clear"
  property var manifest: null

  // Must match omarchy-snap: the gap around and between snapped windows, and
  // how far off a frame a window can sit and still count as snapped there.
  readonly property int gap: 12
  readonly property int tolerance: 6
  property var stacks: []
  // Dots sit faint at rest and come up while something is switching (and
  // while the pointer is over the band; see the strip's HoverHandler).
  property bool lively: false
  Timer { id: livelyTimer; interval: 1600; onTriggered: root.lively = false }

  // ---- Swipes: the indicators are part of the motion ----
  // calmarchy-swipe-progress streams the trackpad's 3/4-finger swipes (the same
  // libinput deltas Hyprland moves workspaces by). While a swipe is under way,
  // the leaving workspace's indicators fade 1 -> 0 and the arriving one's
  // 0 -> 1 exactly as far as the fingers have gone; on release they finish over
  // the rest of the slide. Swipe distance and slide time match looknfeel.lua's
  // scale_swipes(): 350 and 450ms on the laptop, x sqrt(width/1280) capped 1.6.
  property bool swiping: false
  property real swipeDx: 0
  property int swipeMon: -1
  property int swipeFrom: -1
  property real releaseMs: 350
  function swipeScale() {
    var mons = Hyprland.monitors.values
    for (var i = 0; i < mons.length; i++) {
      var mi = mons[i].lastIpcObject
      if (mi && mi.id === root.swipeMon && mi.scale)
        return Math.max(1, Math.min(1.6, Math.sqrt((mi.width / mi.scale) / 1280)))
    }
    return 1
  }
  readonly property real swipeProgress: swiping ? Math.min(1, Math.abs(swipeDx) / (350 * swipeScale())) : 0
  // Fingers moving left (negative dx) go to the next workspace, staying inside
  // the display's block of five (ids n*10+1 .. n*10+5).
  readonly property int swipeTarget: {
    if (swipeFrom < 1) return -1
    var base = Math.floor((swipeFrom - 1) / 10) * 10, slot = swipeFrom - base
    var next = slot + (swipeDx < 0 ? 1 : -1)
    return next >= 1 && next <= 5 ? base + next : -1
  }
  Process {
    id: swipeProc
    command: ["calmarchy-swipe-progress"]
    running: true
    stdout: SplitParser {
      onRead: function(line) {
        var parts = String(line).split(" ")
        if (parts[0] === "begin") {
          var fm = Hyprland.focusedMonitor
          root.swipeMon = fm && fm.lastIpcObject ? fm.lastIpcObject.id : -1
          root.swipeFrom = fm && fm.activeWorkspace ? fm.activeWorkspace.id : -1
          root.swipeDx = 0
          root.swiping = true
        } else if (parts[0] === "move" && root.swiping) {
          root.swipeDx += Number(parts[1]) || 0
        } else if (parts[0] === "end" && root.swiping) {
          // Finish over the part of the slide that's left.
          root.releaseMs = Math.max(120, (1 - root.swipeProgress) * 450 * root.swipeScale())
          root.swiping = false
        }
      }
    }
    // No touchpad access yet (or it restarted): try again later.
    onExited: swipeRetry.restart()
  }
  Timer { id: swipeRetry; interval: 30000; onTriggered: swipeProc.running = true }

  // Every frame omarchy-snap can put a window in, for one monitor.
  function framesFor(m) {
    var r = m.reserved || [0, 0, 0, 0]
    // Clear bars: the top bar includes the top gap (omarchy-bands).
    var tg = root.clearBands ? 0 : gap
    var ax = m.x + r[0] + gap, ay = m.y + r[1] + tg
    var aw = m.width / m.scale - r[0] - r[2] - 2 * gap
    var ah = m.height / m.scale - r[1] - r[3] - tg - gap
    var cw = (aw - gap) / 2, ch = (ah - gap) / 2, tw = (aw - 2 * gap) / 3
    function f(name, x, y, w, h) { return { name: name, x: Math.floor(x), y: Math.floor(y), w: Math.floor(w), h: Math.floor(h) } }
    return [
      f("full", ax, ay, aw, ah),
      f("left", ax, ay, cw, ah), f("right", ax + cw + gap, ay, cw, ah),
      f("top", ax, ay, aw, ch), f("bottom", ax, ay + ch + gap, aw, ch),
      f("tl", ax, ay, cw, ch), f("tr", ax + cw + gap, ay, cw, ch),
      f("bl", ax, ay + ch + gap, cw, ch), f("br", ax + cw + gap, ay + ch + gap, cw, ch)
    ]
  }

  function frameOf(w, frames) {
    for (var i = 0; i < frames.length; i++) {
      var fr = frames[i]
      if (Math.abs(w.x - fr.x) <= tolerance && Math.abs(w.y - fr.y) <= tolerance
          && Math.abs(w.w - fr.w) <= tolerance && Math.abs(w.h - fr.h) <= tolerance)
        return fr.name
    }
    return ""
  }

  // A window snapped into a panel is docked there; stacks of 2+ get dots.
  function rebuild() {
    var framesByMonitor = {}
    var monitors = Hyprland.monitors.values
    for (var m = 0; m < monitors.length; m++) {
      var mi = monitors[m].lastIpcObject
      if (mi && mi.width) framesByMonitor[mi.id] = framesFor(mi)
    }
    var groups = {}, order = []
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var ipc = toplevels[i].lastIpcObject
      if (!ipc || !ipc.at || !ipc.size || !ipc.mapped || ipc.hidden || !ipc.workspace) continue
      if (ipc.workspace.id < 1 || ipc.fullscreen) continue
      var frames = framesByMonitor[ipc.monitor]
      if (!frames) continue
      var w = {
        address: String(ipc.address), ws: ipc.workspace.id, mon: ipc.monitor,
        x: ipc.at[0], y: ipc.at[1], w: ipc.size[0], h: ipc.size[1],
        recency: ipc.focusHistoryID === undefined ? 9999 : ipc.focusHistoryID
      }
      var frame = frameOf(w, frames)
      if (!frame) continue
      var key = w.ws + ":" + ipc.monitor + ":" + frame
      if (!groups[key]) { groups[key] = []; order.push(key) }
      groups[key].push(w)
    }
    order.sort()
    // Each panel's front window: the most recently focused one in it.
    var fronts = {}
    for (var f = 0; f < order.length; f++)
      fronts[order[f]] = groups[order[f]].reduce(function(best, x) { return x.recency < best.recency ? x : best }, groups[order[f]][0])
    // A panel is buried when a more recently focused window's frame contains
    // its own (a full-screen one over a half, say). Buried panels keep their
    // dots, dimmed, so they can be clicked back up; the panel burying them
    // gets dots too, even a lone full-screen window, centered (the middle of
    // the screen for a full one). Otherwise only stacks of 2+ get dots.
    function covers(b, a) {
      return b.ws === a.ws && b.recency < a.recency
        && b.x <= a.x + tolerance && b.y <= a.y + tolerance
        && b.x + b.w >= a.x + a.w - tolerance && b.y + b.h >= a.y + a.h - tolerance
    }
    var buried = {}, burying = {}
    for (var a in fronts) for (var b in fronts) {
      if (a !== b && covers(fronts[b], fronts[a])) { buried[a] = true; burying[b] = true }
    }
    var out = []
    for (var k = 0; k < order.length; k++) {
      var key = order[k], g = groups[key]
      if (g.length < 2 && !buried[key] && !burying[key]) continue
      g.sort(function(p, q) { return p.address < q.address ? -1 : 1 })
      var front = fronts[key]
      out.push({
        key: key, ws: g[0].ws, mon: g[0].mon, centerX: g[0].x + g[0].w / 2, buried: !!buried[key],
        windows: g.map(function(x) { return { address: x.address, front: x.address === front.address && !buried[key] } })
      })
    }
    var json = JSON.stringify(out)
    if (json !== JSON.stringify(root.stacks)) {
      root.stacks = out
      // Something switched (focus moved, a stack rotated, a window came or
      // went): bring the dots up for a moment.
      root.lively = true
      livelyTimer.restart()
    }
  }

  // Floating moves and resizes raise no Hyprland event, so poll lightly.
  Timer {
    interval: 400; running: true; repeat: true; triggeredOnStart: true
    onTriggered: { Hyprland.refreshToplevels(); Hyprland.refreshMonitors() }
  }
  Connections {
    target: Hyprland
    function onRawEvent(event) { Hyprland.refreshToplevels() }
  }
  Connections {
    target: Hyprland.toplevels
    function onValuesChanged() { Qt.callLater(root.rebuild) }
  }
  Instantiator {
    model: Hyprland.toplevels
    delegate: Connections {
      required property var modelData
      target: modelData
      function onLastIpcObjectChanged() { Qt.callLater(root.rebuild) }
    }
  }

  Variants {
    model: Quickshell.screens

    PanelWindow {
      id: strip
      required property var modelData
      screen: modelData

      readonly property var monitor: Hyprland.monitorFor(screen)
      readonly property var ipc: monitor ? monitor.lastIpcObject : null
      readonly property int workspaceId: monitor && monitor.activeWorkspace ? monitor.activeWorkspace.id : -1
      readonly property int monitorX: ipc ? ipc.x : 0
      // The bottom letterbox band's height (its reserved edge).
      // The strip is the 12pt pane gap under the windows (no bottom band), the
      // same margin panes have between them and at the sides: a 4pt bar with
      // 4pt above and below.
      readonly property int bandHeight: root.gap
      HoverHandler { id: bandHover }

      // Drawn over the black bottom band, under the stacks. Reserves nothing.
      // The band is otherwise dead space, so the whole strip takes clicks:
      // clicking a dot brings that window to the front of its stack.
      color: "transparent"
      WlrLayershell.namespace: "bradgessler-stacks"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      anchors { bottom: true; left: true; right: true }
      implicitHeight: bandHeight

      Repeater {
        // Every stack on this display's workspaces is kept; only the shown
        // workspace's are visible, so switching workspaces crossfades instead
        // of popping. (Hyprland doesn't report swipe progress, so this follows
        // the switch, not the finger.)
        // ScriptModel keeps each stack's delegate alive across updates (keyed by
        // workspace:monitor:panel), so its opacity animates instead of resetting.
        model: ScriptModel {
          objectProp: "key"
          values: root.stacks.filter(function(s) { return strip.ipc && s.mon === strip.ipc.id })
        }

        Row {
          id: dots
          required property var modelData
          spacing: 0
          readonly property bool shown: modelData.ws === strip.workspaceId
          // During a swipe on this display, follow the fingers; otherwise show
          // the active workspace's indicators.
          readonly property real target: (root.swiping && strip.ipc && root.swipeMon === strip.ipc.id)
            ? (modelData.ws === root.swipeFrom ? 1 - root.swipeProgress
               : modelData.ws === root.swipeTarget ? root.swipeProgress : 0)
            : (shown ? 1 : 0)
          // Start invisible and bind afterwards, so a freshly created row fades
          // up too (a binding's first value never animates).
          opacity: 0
          Component.onCompleted: opacity = Qt.binding(function() { return dots.target })
          visible: opacity > 0
          enabled: shown
          // Mid-swipe the opacity tracks the fingers directly; on release (or a
          // keyboard switch) it eases the rest of the way.
          Behavior on opacity {
            enabled: !root.swiping
            NumberAnimation { duration: root.releaseMs; easing.type: Easing.OutCubic }
          }

          // No backdrop pill: in the bottom margin it butted against the window
          // edge. The bars float alone, centered between window and screen edge.
          Rectangle {
            visible: false
            parent: dots.parent
            z: -1
            x: dots.x - 4; width: dots.width + 8
            height: strip.height; radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: Qt.rgba(0, 0, 0, 0.38)
            antialiasing: true
          }
          anchors.verticalCenter: parent.verticalCenter
          // Centered in the gap from the window's edge to the screen's edge
          // (Brad reads the shadow as gap, not window). Measured with the
          // brightness-profile check in the calmarchy skill.
          anchors.verticalCenterOffset: 0
          x: Math.round(modelData.centerX - strip.monitorX - width / 2)

          Repeater {
            model: dots.modelData.windows

            // A 12pt-wide, band-high hit target around each 6pt dot (same
            // 12pt pitch as before), so it is easy to click.
            Item {
              id: hit
              required property var modelData
              width: 18; height: strip.height

              Rectangle {
                anchors.centerIn: parent
                // Thin rounded bars, centered in the 12pt margin under the pane.
                width: 14; height: 2; radius: 1
                antialiasing: true
                color: Color.bar.text
                // The window that just came to the front: its dot fades up, then
                // settles. The rest stay faint (a little more over the band).
                opacity: area.containsMouse ? 0.9
                  : hit.modelData.front ? (root.lively ? 1.0 : 0.7)
                  : (bandHover.hovered ? 0.5 : 0.32)
                Behavior on opacity { NumberAnimation { duration: Style.duration(root.lively ? 260 : 700); easing.type: Easing.OutCubic } }
              }

              MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                  var w = 'window = "address:' + hit.modelData.address + '"'
                  Quickshell.execDetached(["hyprctl", "--batch",
                    "dispatch hl.dsp.focus({ " + w + " }); dispatch hl.dsp.window.bring_to_top()"])
                  Qt.callLater(function() { Hyprland.refreshToplevels() })
                }
              }
            }
          }
        }
      }
    }
  }
}
