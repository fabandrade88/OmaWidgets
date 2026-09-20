import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "model/Settings.js" as Settings

// The same cards on a dimmed full-screen surface, summoned by keybind.
//
// This is the second way to read them: the desktop layer is for a glance at an
// uncovered desktop, this is for a look without leaving what you are doing. Both
// render the same CardStack against the same services, so there is one layout to
// maintain and one set of readings.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  property var config: Settings.DEFAULTS
  property bool opened: false

  signal dismissed()
  signal profileRequested(string profile)

  // The overlay lays the cards out side by side: it has the whole screen, so a
  // single tall column would waste it.
  //
  // The count comes from the model rather than from the stack below. Reading it
  // off the stack would make the stack's config depend on the stack's own
  // contents, which is a binding loop QML resolves by handing out undefined.
  readonly property var baseSettings: Settings.normalize(config)
  readonly property int cardCount: Settings.visibleCards(
    baseSettings, !!(pods && pods.hasBattery)).length

  readonly property var overlayConfig: {
    var merged = ({})
    for (var key in baseSettings) merged[key] = baseSettings[key]
    merged.columns = Math.max(1, Math.min(4, cardCount))
    merged.compact = false
    return merged
  }

  PanelWindow {
    id: surface
    visible: root.opened
    color: "transparent"

    anchors { top: true; bottom: true; left: true; right: true }
    WlrLayershell.namespace: "omawidgets-overlay"
    WlrLayershell.layer: WlrLayer.Overlay
    // Exclusive focus is what makes Escape reach the key catcher below rather
    // than the window underneath.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    exclusionMode: ExclusionMode.Ignore

    Rectangle {
      anchors.fill: parent
      color: Color.menu.scrim
    }

    // Clicking the scrim dismisses. The stack sits above this with its own
    // swallowing MouseArea, so a click on a card never closes the overlay.
    MouseArea {
      anchors.fill: parent
      onClicked: root.dismissed()
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.dismissed()

      CardStack {
        id: stack
        anchors.centerIn: parent
        system: root.system
        gpuService: root.gpuService
        pods: root.pods
        power: root.power
        config: root.overlayConfig
        onProfileRequested: function (profile) { root.profileRequested(profile) }

        MouseArea {
          anchors.fill: parent
          // Swallows clicks that land on the stack's own padding so only the
          // scrim dismisses.
          onClicked: {}
        }
      }
    }
  }

  // Layer-shell hands the surface keyboard focus, but Qt still needs an
  // active-focus target inside it before Keys.onPressed fires. Deferred so the
  // surface is mapped and laid out first.
  onOpenedChanged: if (opened) Qt.callLater(function () { keyCatcher.forceActiveFocus() })
}
