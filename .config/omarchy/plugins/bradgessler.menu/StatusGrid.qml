import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower
import qs.Commons
import qs.Commons as Commons

// The status that used to live in the top bar's tray, as a column beside the
// menu rows. Each row matches a menu row's height, icon and type, with the
// reading on the right; clicking it closes the menu and opens that item's own
// Omarchy panel (which drops from the top right as usual).
Item {
  id: root

  // Set by Menu.qml.
  property bool active: false
  property color foreground: "white"
  property color hoverBackground: Util.alpha(foreground, 0.08)
  property string fontFamily: Style.font.family
  property int radius: 0
  signal activated(string command)

  property int rowHeight: Style.space(50)
  property int rowSpacing: Style.spacing.xs

  implicitHeight: tiles.length * rowHeight + (tiles.length - 1) * rowSpacing

  // ---------- Wi-Fi ----------
  property string netType: ""
  property string ssid: ""
  property int signalDbm: 0
  Process {
    id: netProc
    command: ["omarchy-network-status", "--verbose"]
    stdout: StdioCollector {
      onStreamFinished: {
        var type = "", ssid = "", dbm = 0
        String(text).split("\n").forEach(function(line) {
          var tab = line.indexOf("\t")
          if (tab < 0) return
          var key = line.slice(0, tab), value = line.slice(tab + 1)
          if (key === "type") type = value
          else if (key === "ssid") ssid = value
          else if (key === "signal_dbm") dbm = Number(value) || 0
        })
        root.netType = type
        root.ssid = ssid
        root.signalDbm = dbm
      }
    }
  }
  readonly property string wifiGlyph: {
    if (netType === "ethernet") return "󰈀"
    if (netType !== "wifi") return "󰖪"
    if (signalDbm >= -60) return "󰤨"
    if (signalDbm >= -70) return "󰤥"
    if (signalDbm >= -80) return "󰤢"
    return "󰤟"
  }
  readonly property string wifiValue: netType === "wifi" ? (ssid || "Connected")
    : netType === "ethernet" ? "Ethernet" : "Off"

  // ---------- Bluetooth ----------
  readonly property var btAdapter: Bluetooth.defaultAdapter
  readonly property bool btOn: !!btAdapter && btAdapter.enabled
  readonly property var btConnected: {
    var list = Bluetooth.devices ? Bluetooth.devices.values : []
    return list.filter(function(d) { return d && d.connected })
  }
  readonly property string btValue: !btOn ? "Off"
    : btConnected.length === 1 ? (btConnected[0].name || btConnected[0].deviceName || "Connected")
    : btConnected.length > 1 ? btConnected.length + " devices"
    : "On"

  // ---------- Battery ----------
  readonly property var battery: UPower.displayDevice
  readonly property bool batteryPresent: !!battery && battery.isPresent
  readonly property real batteryLevel: batteryPresent ? Math.max(0, Math.min(1, battery.percentage)) : 0
  readonly property bool charging: batteryPresent && (battery.state === UPowerDeviceState.Charging || battery.state === UPowerDeviceState.FullyCharged || battery.state === UPowerDeviceState.PendingCharge)
  readonly property string batteryGlyph: {
    if (charging) return "󰂄"
    var glyphs = ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    return glyphs[Math.round(batteryLevel * 10)]
  }
  readonly property string batteryValue: !batteryPresent ? "AC power"
    : Math.round(batteryLevel * 100) + "%" + (charging ? (batteryLevel >= 1 ? " · Full" : " · Charging") : "")

  // ---------- Sound ----------
  readonly property var sink: Pipewire.defaultAudioSink
  PwObjectTracker { objects: root.sink ? [root.sink] : [] }
  readonly property bool sinkReady: !!sink && !!sink.audio
  readonly property bool muted: sinkReady && sink.audio.muted
  readonly property int volume: sinkReady ? Math.round(sink.audio.volume * 100) : 0
  readonly property string soundGlyph: !sinkReady || muted ? "󰖁" : volume >= 60 ? "󰕾" : volume >= 25 ? "󰖀" : "󰕿"
  readonly property string soundValue: !sinkReady ? "No output" : muted ? "Muted" : volume + "%"

  // ---------- Weather ----------
  property string weatherValue: "—"
  property string weatherGlyph: "󰖐"
  property real weatherFetchedAt: 0
  Process {
    id: weatherProc
    command: ["curl", "-fsS", "--max-time", "6", "https://wttr.in/?format=%t|%C"]
    stdout: StdioCollector {
      onStreamFinished: {
        var parts = String(text).trim().split("|")
        if (parts.length < 2) return
        var temp = parts[0].replace(/^\+/, "")
        var cond = parts[1].trim()
        root.weatherValue = temp + " · " + cond
        root.weatherGlyph = root.glyphForCondition(cond)
        root.weatherFetchedAt = Date.now()
      }
    }
  }
  function glyphForCondition(c) {
    c = c.toLowerCase()
    if (c.indexOf("thunder") >= 0) return "󰖓"
    if (c.indexOf("snow") >= 0 || c.indexOf("sleet") >= 0) return "󰖘"
    if (c.indexOf("rain") >= 0 || c.indexOf("drizzle") >= 0 || c.indexOf("shower") >= 0) return "󰖗"
    if (c.indexOf("fog") >= 0 || c.indexOf("mist") >= 0 || c.indexOf("haze") >= 0) return "󰖑"
    if (c.indexOf("partly") >= 0) return "󰖕"
    if (c.indexOf("cloud") >= 0 || c.indexOf("overcast") >= 0) return "󰖐"
    var hour = new Date().getHours()
    return hour >= 6 && hour < 19 ? "󰖙" : "󰖔"
  }

  // ---------- Updates ----------
  property bool updateAvailable: false
  property real updateCheckedAt: 0
  Process {
    id: updateProc
    command: ["omarchy-update-available"]
    onExited: function(code) {
      root.updateAvailable = code === 0
      root.updateCheckedAt = Date.now()
    }
  }

  // Refresh what can go stale while the menu is closed, every time it opens,
  // and keep the cheap readings live while it stays open.
  function refresh() {
    if (!netProc.running) netProc.running = true
    var now = Date.now()
    if (!weatherProc.running && now - weatherFetchedAt > 20 * 60 * 1000) weatherProc.running = true
    if (!updateProc.running && now - updateCheckedAt > 10 * 60 * 1000) updateProc.running = true
  }
  onActiveChanged: if (active) refresh()
  Component.onCompleted: refresh()
  Timer {
    interval: 5000
    repeat: true
    running: root.active
    onTriggered: if (!netProc.running) netProc.running = true
  }

  readonly property var tiles: [
    { label: "Wi-Fi", glyph: wifiGlyph, value: wifiValue, dim: netType === "", command: "omarchy-shell shell summon omarchy.network" },
    { label: "Bluetooth", glyph: btOn ? (btConnected.length ? "󰂱" : "󰂯") : "󰂲", value: btValue, dim: !btOn, command: "omarchy-shell shell summon omarchy.bluetooth" },
    { label: "Battery", glyph: batteryGlyph, value: batteryValue, dim: false, command: "omarchy-shell shell summon omarchy.power" },
    { label: "Sound", glyph: soundGlyph, value: soundValue, dim: muted, command: "omarchy-shell shell summon omarchy.audio" },
    { label: "Weather", glyph: weatherGlyph, value: weatherValue, dim: false, command: "omarchy-shell shell summon omarchy.weather" },
    { label: "Updates", glyph: updateAvailable ? "󰚰" : "󰄬", value: updateAvailable ? "Available" : "Up to date", dim: !updateAvailable, command: "omarchy-launch-floating-terminal-with-presentation omarchy-update" }
  ]

  Column {
    id: list
    anchors.left: parent.left
    anchors.right: parent.right
    spacing: root.rowSpacing

    Repeater {
      model: root.tiles

      delegate: Rectangle {
        id: tile
        required property var modelData
        width: list.width
        height: root.rowHeight
        radius: root.radius
        color: mouse.containsMouse ? root.hoverBackground : "transparent"

        Text {
          id: glyph
          anchors.left: parent.left
          anchors.leftMargin: Style.space(8)
          anchors.verticalCenter: parent.verticalCenter
          width: Style.space(36)
          horizontalAlignment: Text.AlignHCenter
          text: tile.modelData.glyph
          color: root.foreground
          opacity: tile.modelData.dim ? 0.45 : 1
          font.family: root.fontFamily
          font.pixelSize: Style.font.iconLarge
        }

        Text {
          id: label
          anchors.left: glyph.right
          anchors.leftMargin: Style.space(6)
          anchors.verticalCenter: parent.verticalCenter
          text: tile.modelData.label
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          font.weight: Font.Medium
        }

        Text {
          anchors.left: label.right
          anchors.leftMargin: Style.space(12)
          anchors.right: parent.right
          anchors.rightMargin: Style.space(14)
          anchors.verticalCenter: parent.verticalCenter
          horizontalAlignment: Text.AlignRight
          text: tile.modelData.value
          color: root.foreground
          opacity: tile.modelData.dim ? 0.4 : 0.6
          font.family: root.fontFamily
          font.pixelSize: Style.font.heading
          elide: Text.ElideRight
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.activated(tile.modelData.command)
        }
      }
    }
  }
}
