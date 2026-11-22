import QtQuick
import "../cards"
import "../model/Cells.js" as Cells
import "../model/Layout.js" as Layout

// One card on the tile grid: drawn at its cell, a fixed number of cells in
// size, and dragged by its body like the cards in the columns are.
//
// A tap selects and a drag moves, for the same reason as in PackedLayout: a
// TapHandler fires only when nothing inside the card took the press, and a
// DragHandler takes over only past the drag threshold, so the profile segments,
// the transport and the X keep working.
Item {
  id: slot

  required property string cardId
  required property var board

  readonly property var tile: board.layout[cardId] || null
  readonly property var box: Cells.rect(tile, board.metrics)
  // Both, so a tile rebuilt mid-drag does not inherit a drag it is not doing.
  readonly property bool dragging: board.draggingId === cardId && dragHandler.active
  property real dragX: 0
  property real dragY: 0

  // A card the board could not place has no box and takes no input.
  visible: tile !== null
  width: tile ? box.width : 0
  height: tile ? box.height : 0
  x: dragging ? dragX : box.x
  y: dragging ? dragY : box.y
  z: dragging ? 10 : 0
  opacity: dragging ? 0.85 : 1

  // Animated, so a tile pushed out of the way is visibly the same tile.
  Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
  Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

  // The cells are as tall as the tallest fixed tile needs, so every card says
  // what it needs. The to-do tile scrolls its list instead, so it asks nothing.
  function measure() {
    if (!tile || cardId === Layout.CARD_TODO) return
    board.claimCellHeight(Cells.cellHeightFor(card.naturalHeight, tile.h, board.metrics.gap))
  }

  onTileChanged: measure()

  Component.onCompleted: board.registerSlot(cardId, slot)
  Component.onDestruction: {
    if (board.draggingId === cardId) board.cancelDrag()
    board.unregisterSlot(cardId)
  }

  CardLoader {
    id: card
    width: slot.width
    tileHeight: slot.height
    inGrid: true
    cardId: slot.cardId
    selected: slot.board.selectedId === slot.cardId
    settings: slot.board.settings
    arrangeable: slot.board.arrangeable
    selectionSource: slot.board
    system: slot.board.system; gpuService: slot.board.gpuService; pods: slot.board.pods
    power: slot.board.power; media: slot.board.media; todos: slot.board.todos
    onNaturalHeightChanged: slot.measure()
    onHideRequested: function (id) { slot.board.hideRequested(id) }
    onProfileRequested: function (profile) { slot.board.profileRequested(profile) }
    onComposingChanged: function (active) { slot.board.composingChanged(active) }
  }

  TapHandler {
    enabled: slot.board.arrangeable
    gesturePolicy: TapHandler.ReleaseWithinBounds
    onTapped: slot.board.selectRequested(slot.cardId)
  }

  DragHandler {
    id: dragHandler
    enabled: slot.board.arrangeable
    target: null
    onActiveChanged: {
      if (active) {
        slot.dragX = slot.x
        slot.dragY = slot.y
        slot.board.beginDrag(slot.cardId)
      } else {
        slot.board.endDrag()
      }
    }
    onCentroidChanged: {
      if (!active) return
      slot.dragX = slot.x + centroid.position.x - centroid.pressPosition.x
      slot.dragY = slot.y + centroid.position.y - centroid.pressPosition.y
      // The pointer, not the tile, decides whether this is still a drop on the
      // board: let go over the bar or off the screen and nothing moves.
      var at = slot.mapToItem(slot.board, centroid.position.x, centroid.position.y)
      var onBoard = at.x >= 0 && at.y >= 0 && at.x < slot.board.width && at.y < slot.board.height
      slot.board.dragTo(slot.dragX, slot.dragY, onBoard)
    }
  }
}
