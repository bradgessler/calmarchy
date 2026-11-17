import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Io

// A solid black band along the bottom of every screen, as tall as the top bar,
// so the wallpaper reads as a letterboxed picture between two black strips. It
// reserves its height, so snapped windows stop above it.
Item {
  id: root

  property var shell: null
  property var manifest: null

  // Matches the top bar, which is 32pt to cover the MacBook notch.
  readonly property int bandHeight: 32

  // "black" (default) or "clear", from ~/.config/omarchy/bands, set by
  // omarchy-bands. Clear still reserves the band so windows stop above it.
  FileView {
    id: bandsFile
    path: Quickshell.env("HOME") + "/.config/omarchy/bands"
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
  }
  readonly property bool clear: bandsFile.loaded && bandsFile.text().trim() === "clear"

  Variants {
    model: Quickshell.screens

    PanelWindow {
      required property var modelData
      screen: modelData

      color: root.clear ? "transparent" : "#000000"
      WlrLayershell.namespace: "bradgessler-letterbox"
      WlrLayershell.layer: WlrLayer.Top
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      exclusionMode: ExclusionMode.Normal
      exclusiveZone: root.bandHeight
      anchors { bottom: true; left: true; right: true }
      implicitHeight: root.bandHeight
      mask: Region {}
    }
  }
}
