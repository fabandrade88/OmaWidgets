import QtQuick
import Quickshell.Io

// The `omawidgets-bar` IPC target, split out of BarWidget.qml so the widget
// reads as what it draws rather than as a list of remote-control verbs.
//
// Everything here is a thin call onto the widget; nothing decides anything.
Item {
  id: root

  required property var widget
  property string ipcTarget: "omawidgets-bar"

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.widget.open() }
    function close(): void { root.widget.close() }
    function toggle(): void { root.widget.toggle() }
    // Flips the desktop cards without opening anything, for a Hyprland keybind.
    function toggleDesktop(): string { root.widget.toggleDesktop(); return root.widget.config.desktop ? "shown" : "hidden" }

    // Move the cards from a script or a keybind. Settings.normalize rejects a
    // position that does not exist, so the reply says what actually happened
    // rather than echoing the request back.
    function position(name: string): string {
      root.widget.setPosition(name)
      return root.widget.config.position
    }
  }
}
