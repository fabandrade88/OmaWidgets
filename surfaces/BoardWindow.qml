import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.Ui
import "../model/Layout.js" as Layout

// The tile grid on one screen's desktop.
//
// It covers the whole usable area, because a tile may sit in any cell, but it
// only takes input where a tile is: the mask below is the tiles themselves, so
// a double-click on the empty wallpaper still reaches Omarchy's background and
// theme pickers. While a tile is being dragged the mask lifts, so the drag
// keeps the pointer wherever it goes.
//
// Everything else is the desktop surface's own decisions, repeated: the bottom
// layer, the keyboard only while something is typed into, and the bar's space
// respected rather than reserved.
PanelWindow {
  id: surface

  required property var modelData
  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  required property var todos
  property var config: ({})
  property bool showCards: true
  property string selectedId: ""
  property bool composing: false

  signal selectRequested(string id)
  signal tilesRequested(var tiles)
  signal hideRequested(string id)
  signal profileRequested(string profile)
  signal composingRequested(bool active)

  readonly property alias board: tileBoard

  screen: modelData
  visible: showCards && !remapGuard.remapping && tileBoard.ids.length > 0
  color: "transparent"

  WlrLayershell.namespace: "omawidgets-desktop"
  WlrLayershell.layer: WlrLayer.Bottom
  WlrLayershell.keyboardFocus: composing ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: 0

  anchors { top: true; bottom: true; left: true; right: true }

  mask: tileBoard.draggingId !== "" ? null : tilesRegion

  // One region per card that exists, each following its tile. A card that is
  // not on the board has no item, and so no region.
  Region {
    id: tilesRegion
    Region { item: tileBoard.slotItems[Layout.CARD_SYSTEM] || null }
    Region { item: tileBoard.slotItems[Layout.CARD_MEDIA] || null }
    Region { item: tileBoard.slotItems[Layout.CARD_TODO] || null }
    Region { item: tileBoard.slotItems[Layout.CARD_PODS] || null }
    Region { item: tileBoard.slotItems[Layout.CARD_BATTERY] || null }
    Region { item: tileBoard.slotItems[Layout.CARD_POWER] || null }
  }

  ScreenMoveRemap {
    id: remapGuard
    window: surface
  }

  TileBoard {
    id: tileBoard
    anchors.fill: parent
    anchors.leftMargin: surface.config.marginX
    anchors.rightMargin: surface.config.marginX
    anchors.topMargin: surface.config.marginY
    anchors.bottomMargin: surface.config.marginY
    system: surface.system
    gpuService: surface.gpuService
    pods: surface.pods
    power: surface.power
    media: surface.media
    todos: surface.todos
    settings: surface.config
    presence: ({
      hasPods: !!(surface.pods && surface.pods.hasBattery),
      hasMedia: !!(surface.media && surface.media.hasMedia)
    })
    arrangeable: true
    selectedId: surface.selectedId
    onSelectRequested: function (id) { surface.selectRequested(id) }
    onTilesRequested: function (tiles) { surface.tilesRequested(tiles) }
    onHideRequested: function (id) { surface.hideRequested(id) }
    onProfileRequested: function (profile) { surface.profileRequested(profile) }
    onComposingChanged: function (active) { surface.composingRequested(active) }
  }
}
