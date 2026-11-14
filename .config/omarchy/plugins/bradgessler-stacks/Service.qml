import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.Commons

// Windows that share a pane (overlap by a quarter or more) form a stack. Each
// stack of two or more gets a row of dots in the top bar, vertically centered
// in it and horizontally centered over the stack. The front window's dot is brighter. Super+Tab / Alt+Tab rotate the stack.
Item {
  id: root

  property var shell: null
  property var manifest: null

  readonly property real overlap: 0.25
  property var stacks: []

  function overlapRatio(a, b) {
    var x1 = Math.max(a.x, b.x), x2 = Math.min(a.x + a.w, b.x + b.w)
    var y1 = Math.max(a.y, b.y), y2 = Math.min(a.y + a.h, b.y + b.h)
    if (x2 <= x1 || y2 <= y1) return 0
    var smaller = Math.min(a.w * a.h, b.w * b.h)
    return smaller > 0 ? (x2 - x1) * (y2 - y1) / smaller : 0
  }

  function rebuild() {
    var wins = []
    var toplevels = Hyprland.toplevels.values
    for (var i = 0; i < toplevels.length; i++) {
      var ipc = toplevels[i].lastIpcObject
      if (!ipc || !ipc.at || !ipc.size || !ipc.mapped || ipc.hidden || !ipc.workspace) continue
      if (ipc.workspace.id < 1) continue
      wins.push({
        address: String(ipc.address), ws: ipc.workspace.id, monitor: ipc.monitor,
        x: ipc.at[0], y: ipc.at[1], w: ipc.size[0], h: ipc.size[1],
        recency: ipc.focusHistoryID === undefined ? 9999 : ipc.focusHistoryID
      })
    }
    // Union windows on the same workspace that overlap enough.
    var parent = wins.map(function(_, k) { return k })
    function find(k) { while (parent[k] !== k) k = parent[k] = parent[parent[k]]; return k }
    for (var a = 0; a < wins.length; a++)
      for (var b = a + 1; b < wins.length; b++)
        if (wins[a].ws === wins[b].ws && overlapRatio(wins[a], wins[b]) >= root.overlap)
          parent[find(a)] = find(b)
    var groups = {}
    for (var n = 0; n < wins.length; n++) {
      var r = find(n)
      if (!groups[r]) groups[r] = []
      groups[r].push(wins[n])
    }
    var out = []
    for (var key in groups) {
      var g = groups[key]
      if (g.length < 2) continue
      g.sort(function(p, q) { return p.address < q.address ? -1 : 1 })
      var front = g.reduce(function(best, w) { return w.recency < best.recency ? w : best }, g[0])
      var left = Infinity, right = -Infinity
      g.forEach(function(w) { left = Math.min(left, w.x); right = Math.max(right, w.x + w.w) })
      out.push({
        ws: g[0].ws, centerX: (left + right) / 2,
        windows: g.map(function(w) { return { address: w.address, front: w.address === front.address } })
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
          x: Math.round(modelData.centerX - strip.monitorX - width / 2)

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
