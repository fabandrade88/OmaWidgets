import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Ui
import "model/Settings.js" as Settings

// The cards on the wallpaper, the way macOS puts widgets on the desktop.
//
// Two decisions make it behave like a desktop widget rather than an overlay:
//
//   * WlrLayer.Bottom sits above the wallpaper and below every application
//     window, so the cards are there when you look at the desktop and gone when
//     you are working.
//   * The window is sized to the cards, not to the screen, and anchored to one
//     corner. A full-screen surface would swallow the double-click Omarchy uses
//     on empty wallpaper to open the background and theme pickers.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  property var config: Settings.DEFAULTS
  property bool showCards: true

  signal profileRequested(string profile)

  readonly property var placement: Settings.anchorsFor(config.position)

  // An empty `monitor` setting means every screen. A name that matches nothing
  // yields no surface, which is the honest outcome of asking for a screen that
  // is not attached.
  readonly property var targetScreens: {
    var wanted = String(config.monitor || "")
    var all = Quickshell.screens
    if (wanted === "") return all
    var out = []
    for (var i = 0; i < all.length; i++) if (all[i] && all[i].name === wanted) out.push(all[i])
    return out
  }

  Variants {
    model: root.targetScreens

    PanelWindow {
      id: surface
      required property var modelData

      screen: modelData
      visible: root.showCards && !remapGuard.remapping && stack.visibleCards.length > 0
      color: "transparent"

      WlrLayershell.namespace: "omawidgets-desktop"
      // Above the wallpaper, below application windows.
      WlrLayershell.layer: WlrLayer.Bottom
      // The cards are clickable but never take the keyboard: a desktop widget
      // that stole focus from the focused window would be a bug, not a feature.
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      // Reserves no space, so windows tile over the whole screen as before.
      exclusionMode: ExclusionMode.Ignore

      anchors {
        top: root.placement.top
        bottom: root.placement.bottom
        left: root.placement.left
        right: root.placement.right
      }

      margins {
        top: root.config.marginY
        bottom: root.config.marginY
        left: root.config.marginX
        right: root.config.marginX
      }

      implicitWidth: stack.implicitWidth
      implicitHeight: stack.implicitHeight

      ScreenMoveRemap {
        id: remapGuard
        window: surface
      }

      CardStack {
        id: stack
        anchors.centerIn: parent
        system: root.system
        gpuService: root.gpuService
        pods: root.pods
        power: root.power
        config: root.config
        onProfileRequested: function (profile) { root.profileRequested(profile) }
      }
    }
  }
}
