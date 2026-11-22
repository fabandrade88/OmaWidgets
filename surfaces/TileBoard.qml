import QtQuick
import qs.Commons
import "../model/Cells.js" as Cells
import "../model/Grid.js" as Grid
import "../model/Layout.js" as Layout

// The full cards as tiles on a board of cells, for the `grid` setting.
//
// It fills whatever it is given — the usable area of one screen, less the
// margins — and works out how many cells fit. Where each card sits is Grid.js's
// answer from the saved cells; this item draws it, follows a drag, and asks for
// the result to be saved. It never writes anything itself: the bar widget owns
// the only write path, the same as for the card order.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  required property var todos
  property var settings: null
  property var presence: Layout.defaultState()
  property bool arrangeable: false
  property string selectedId: ""

  signal selectRequested(string id)
  signal tilesRequested(var tiles)
  signal hideRequested(string id)
  signal profileRequested(string profile)
  signal composingChanged(bool active)

  readonly property var ids: Layout.visibleCards(settings, presence)
  readonly property var saved: settings && settings.tiles ? settings.tiles : ({})

  // As tall as the tallest fixed tile needs at the theme's font size, and never
  // shorter than a floor that fits the cards as they ship. It only grows while
  // the font stays put, so the board does not jump when a card comes and goes,
  // and never past what lets the tallest tile fit on this screen: one card that
  // briefly asks for too much must not push every tile off the board.
  property real measuredCell: 0
  readonly property int tallest: Grid.sizeOf(Layout.CARD_TODO).h
  readonly property real maxCell: height > 0
    ? Math.floor((height + settings.spacing) / tallest) - settings.spacing : Infinity
  readonly property real cellHeight: Math.max(Style.space(46), Math.min(measuredCell, maxCell))
  readonly property int fontSize: Style.fontBaseSize
  onFontSizeChanged: measuredCell = 0

  function claimCellHeight(needed) {
    if (isFinite(needed) && needed > measuredCell) measuredCell = needed
  }

  readonly property var metrics: Cells.metrics(width, height, settings.cardWidth,
    settings.spacing, cellHeight, Grid.CARD_COLUMNS)
  readonly property int cols: metrics.cols
  readonly property int rows: metrics.rows
  readonly property var base: Grid.place(ids, saved, cols, rows, settings.position)

  // During a drag, the board as it would be if the tile were let go now. After a
  // drop, what was dropped, until the write comes back as settings — otherwise
  // the tiles snap back for the moment that round trip takes.
  property var preview: null
  property var held: null
  property var dragBase: null
  property bool dropFits: false
  property string draggingId: ""
  readonly property var layout: preview ? preview : (held ? held : base)

  onSavedChanged: held = null
  // A card arriving or leaving rebuilds every tile, the dragged one included,
  // and a destroyed handler never reports its release. Without this the drag
  // would never end, and the board would go on taking every desktop click.
  // Compared by content: `ids` is a new array on every re-evaluation, and the
  // same cards again rebuild nothing and must not cut a drag short.
  property string idsKey: ""
  onIdsChanged: {
    var key = JSON.stringify(ids)
    if (key === idsKey) return
    idsKey = key
    held = null
    cancelDrag()
  }
  onVisibleChanged: if (!visible) cancelDrag()

  function cancelDrag() {
    draggingId = ""
    preview = null
    dragBase = null
    dropFits = false
  }

  // Each tile's item by card id, for the input mask: the desktop takes clicks on
  // the tiles and nowhere else. Replaced rather than mutated so bindings see it.
  property var slotItems: ({})

  function registerSlot(id, item) {
    var next = ({})
    for (var key in slotItems) next[key] = slotItems[key]
    next[id] = item
    slotItems = next
  }

  function unregisterSlot(id) {
    var next = ({})
    for (var key in slotItems) if (key !== id) next[key] = slotItems[key]
    slotItems = next
  }

  // Which tile, if any, is under a point in this item's coordinates.
  function tileAt(x, y) {
    for (var i = 0; i < ids.length; i++) {
      var tile = layout[ids[i]]
      if (tile && Cells.contains(Cells.rect(tile, metrics), x, y)) return ids[i]
    }
    return ""
  }

  function beginDrag(id) {
    dragBase = layout
    dropFits = false
    preview = dragBase
    draggingId = id
  }

  // (x, y) is the dragged tile's top-left corner, so it lands on the cell that
  // corner is nearest.
  function dragTo(x, y, onBoard) {
    if (draggingId === "" || !dragBase) return
    if (!onBoard) {
      preview = dragBase
      dropFits = false
      return
    }
    var cell = Cells.nearestCell(metrics, x, y)
    var result = Grid.drop(dragBase, draggingId, cell.col, cell.row, cols, rows)
    preview = result.layout
    dropFits = result.fits
  }

  // A drop that fits is kept and asked to be saved; anything else — off the
  // board, or a push off its bottom — puts every tile back where it was.
  function endDrag() {
    if (draggingId === "") return
    var result = preview
    var keep = dropFits && result !== null
    draggingId = ""
    preview = null
    dragBase = null
    if (!keep) return
    var next = Grid.toSaved(result, saved)
    if (JSON.stringify(next) === JSON.stringify(Grid.toSaved(base, saved))) return
    held = result
    heldTimer.restart()
    tilesRequested(next)
  }

  // A write that never comes back — no bar to make it — must not pin the board.
  Timer {
    id: heldTimer
    interval: 3000
    onTriggered: root.held = null
  }

  // Where the dragged tile will land, drawn under everything.
  Rectangle {
    readonly property var target: root.draggingId !== "" && root.preview
      ? Cells.rect(root.preview[root.draggingId], root.metrics) : null
    visible: target !== null && root.dropFits
    x: target ? target.x : 0
    y: target ? target.y : 0
    width: target ? target.width : 0
    height: target ? target.height : 0
    radius: Style.cornerRadius
    color: Util.alpha(Color.accent, 0.12)
    border.color: Util.alpha(Color.accent, 0.6)
    border.width: Math.max(1, Style.space(2))
  }

  Repeater {
    model: root.ids

    TileSlot {
      required property string modelData
      cardId: modelData
      board: root
    }
  }
}
