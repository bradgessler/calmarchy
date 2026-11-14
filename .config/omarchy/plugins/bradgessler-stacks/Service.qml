import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

// Windows snapped into the same omarchy-snap panel form a stack. Each stack of
// two or more gets a row of dots in the top bar, vertically centered and
// horizontally centered over it; the front window's dot is brighter. Windows
// torn off into loose spots get no dot. Super+Tab / Alt+Tab rotate a stack.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Must match omarchy-snap: the gap around and between snapped windows, and
  // how far off a frame a window can sit and still count as snapped there.
  readonly property int gap: 8
  readonly property int tolerance: 6
  property var stacks: []

  // Every frame omarchy-snap can put a window in, for one monitor.
  function framesFor(m) {
    var r = m.reserved || [0, 0, 0, 0]
    var ax = m.x + r[0] + gap, ay = m.y + r[1] + gap
    var aw = m.width / m.scale - r[0] - r[2] - 2 * gap
    var ah = m.height / m.scale - r[1] - r[3] - 2 * gap
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
        address: String(ipc.address), ws: ipc.workspace.id,
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
    var out = []
    for (var k = 0; k < order.length; k++) {
      var g = groups[order[k]]
      // A lone window in a panel needs no dot; dots mean "more under here".
      if (g.length < 2) continue
      g.sort(function(p, q) { return p.address < q.address ? -1 : 1 })
      var front = g.reduce(function(best, x) { return x.recency < best.recency ? x : best }, g[0])
      out.push({
        ws: g[0].ws, centerX: g[0].x + g[0].w / 2,
        windows: g.map(function(x) { return { address: x.address, front: x.address === front.address } })
      })
    }
    var json = JSON.stringify(out)
    if (json !== JSON.stringify(root.stacks)) root.stacks = out
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
      // The top bar's real thickness, notch floor included.
      // The MacBook's camera notch, centered on the built-in panel (about 200pt
      // wide at this scale). Other screens have none.
      readonly property bool hasNotch: String(screen ? screen.name : "").indexOf("eDP") === 0
      readonly property real notchHalf: hasNotch ? 100 : 0
      readonly property real notchLeft: hasNotch ? width / 2 - notchHalf : -1
      readonly property real notchRight: hasNotch ? width / 2 + notchHalf : -1
      readonly property int barHeight: ipc && ipc.reserved ? ipc.reserved[1] : Style.bar.sizeHorizontal

      // Drawn over the top bar, along its bottom edge. Reserves nothing and takes
      // no input, so the bar underneath keeps working.
      color: "transparent"
      WlrLayershell.namespace: "bradgessler-stacks"
      WlrLayershell.layer: WlrLayer.Overlay
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Ignore
      exclusiveZone: 0
      anchors { top: true; left: true; right: true }
      implicitHeight: Math.max(8, barHeight)
      mask: Region {}

      Repeater {
        model: root.stacks.filter(function(s) { return s.ws === strip.workspaceId })

        Row {
          id: dots
          required property var modelData
          spacing: 6
          anchors.verticalCenter: parent.verticalCenter
          // Centered over the stack, unless that puts them under the camera
          // notch; then they sit just to its right.
          readonly property real wantX: Math.round(modelData.centerX - strip.monitorX - width / 2)
          x: (wantX + width > strip.notchLeft && wantX < strip.notchRight) ? strip.notchRight + 10 : wantX

          Repeater {
            model: dots.modelData.windows

            Rectangle {
              required property var modelData
              width: 6; height: 6; radius: 3
              antialiasing: true
              color: Color.bar.text
              opacity: modelData.front ? 0.85 : 0.3
              Behavior on opacity { NumberAnimation { duration: Style.duration(120); easing.type: Easing.OutCubic } }
            }
          }
        }
      }
    }
  }
}
