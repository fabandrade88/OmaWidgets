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

  // With the tile grid the overlay shows the same board, at the same cells. It
  // respects the bar's space to do that, the way the desktop board does, so the
  // two cover the same area — which means the bar is left undimmed.
  readonly property bool grid: Layout.usesGrid(baseSettings)

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
    exclusionMode: root.grid ? ExclusionMode.Normal : ExclusionMode.Ignore

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
        if (boardLoader.item) {
          var onBoard = mapToItem(boardLoader.item, mouse.x, mouse.y)
          if (boardLoader.item.tileAt(onBoard.x, onBoard.y) === "") root.dismissed()
          return
        }
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

      // Loaded rather than hidden, so the cards exist once, in whichever
      // arrangement is showing.
      Loader {
        id: boardLoader
        anchors.fill: parent
        anchors.leftMargin: root.baseSettings.marginX
        anchors.rightMargin: root.baseSettings.marginX
        anchors.topMargin: root.baseSettings.marginY
        anchors.bottomMargin: root.baseSettings.marginY
        active: root.grid
        sourceComponent: TileBoard {
          system: root.system
          gpuService: root.gpuService
          pods: root.pods
          power: root.power
          media: root.media
          todos: root.todos
          settings: root.baseSettings
          presence: ({
            hasPods: !!(root.pods && root.pods.hasBattery),
            hasMedia: !!(root.media && root.media.hasMedia)
          })
          onProfileRequested: function (profile) { root.profileRequested(profile) }
          onComposingChanged: function (active) { root.composing = active }
        }
      }

      Loader {
        id: stack
        anchors.centerIn: parent
        active: !root.grid
        sourceComponent: CardStack {
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
  }

  // Layer-shell hands the surface keyboard focus, but Qt still needs an
  // active-focus target inside it before Keys.onPressed fires. Deferred so the
  // surface is mapped and laid out first.
  onOpenedChanged: if (opened) Qt.callLater(function () { keyCatcher.forceActiveFocus() })
}
