import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui
import "../model/Layout.js" as Layout
import "../model/Settings.js" as Settings

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
  required property var media
  required property var todos
  property var config: Settings.DEFAULTS
  property bool opened: false

  // True while something on a card is being typed into. The key catcher below
  // dispatches h/j/k/l, Space and Return as commands, which would otherwise
  // never reach the to-do composer's fields.
  property bool composing: false

  signal dismissed()
  signal profileRequested(string profile)

  // The overlay lays the cards out side by side: it has the whole screen, so a
  // single tall column would waste it.
  //
  // The count comes from the model rather than from the stack below. Reading it
  // off the stack would make the stack's config depend on the stack's own
  // contents, which is a binding loop QML resolves by handing out undefined.
  readonly property var baseSettings: Settings.normalize(config)
  readonly property int cardCount: Layout.visibleCards(baseSettings, {
    hasPods: !!(pods && pods.hasBattery),
    hasMedia: !!(media && media.hasMedia)
  }).length

  // One row when the screen is wide enough for one, wrapped into further rows
  // when it is not. `surface.width` is the whole screen, less a margin on each
  // side so the outermost cards do not sit against the bezel.
  readonly property int fittingColumns: Layout.columnsThatFit(
    surface.width - 2 * baseSettings.marginX,
    baseSettings.cardWidth, baseSettings.spacing, cardCount)

  readonly property var overlayConfig: {
    var merged = ({})
    for (var key in baseSettings) merged[key] = baseSettings[key]
    merged.columns = fittingColumns
    // The overlay has the whole screen, so it always shows the full cards.
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

    // Clicking away dismisses — which is everywhere except the cards
    // themselves and the gaps between them.
    //
    // The test is the stack's own rectangle rather than a MouseArea laid over
    // the stack: one covering the cards takes every press before they do, and
    // an overlay whose cards cannot be clicked is worse than one that is easy
    // to dismiss by accident.
    MouseArea {
      anchors.fill: parent
      onClicked: function (mouse) {
        var local = mapToItem(stack, mouse.x, mouse.y)
        var inside = local.x >= 0 && local.y >= 0
          && local.x <= stack.width && local.y <= stack.height
        if (!inside) root.dismissed()
      }
    }

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      blocked: root.composing
      onCloseRequested: root.dismissed()

      CardStack {
        id: stack
        anchors.centerIn: parent
        system: root.system
        gpuService: root.gpuService
        pods: root.pods
        power: root.power
        media: root.media
        todos: root.todos
        config: root.overlayConfig
        onProfileRequested: function (profile) { root.profileRequested(profile) }
        onComposingChanged: function (active) { root.composing = active }
      }
    }
  }

  // Layer-shell hands the surface keyboard focus, but Qt still needs an
  // active-focus target inside it before Keys.onPressed fires. Deferred so the
  // surface is mapped and laid out first.
  onOpenedChanged: if (opened) Qt.callLater(function () { keyCatcher.forceActiveFocus() })
}
