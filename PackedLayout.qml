import QtQuick
import "model/Pack.js" as Pack

// The desktop arrangement, shared by the card layout and the tile layout.
//
// Items are placed rather than tabulated: each goes to whichever column is
// currently shortest, so a short card never leaves a hole under it the way a
// Grid's uniform row heights do. An item may span two columns — the compact
// Performance tile is a wide rectangle — and the packer handles that.
//
// It also owns arranging: a tap selects, a drag reorders. The delegate keeps its
// own mouse areas working, because a TapHandler only fires when nothing inside
// took the press, and a DragHandler only takes over past the drag threshold.
Item {
  id: root

  property var ids: []
  property int columns: 1
  property int columnWidth: 268
  property int spacing: 10
  // function(id) -> how many columns this item occupies
  property var spanFor: null
  property Component delegate: null
  property bool arrangeable: true
  property string selectedId: ""

  signal selectRequested(string id)
  signal orderRequested(var ids)
  signal hideRequested(string id)

  // Visual order. Held separately from `ids` so a drag can reorder without
  // changing the Repeater's model, which would tear down and rebuild the cards
  // being dragged.
  property var order: []
  property var boxById: ({})
  property var boxList: []
  property real packedHeight: 0
  property string draggingId: ""

  implicitWidth: columns * columnWidth + Math.max(0, columns - 1) * spacing
  implicitHeight: packedHeight

  property var slots: ({})

  function registerSlot(id, item) {
    slots[id] = item
    scheduleRelayout()
  }

  function unregisterSlot(id) {
    delete slots[id]
    scheduleRelayout()
  }

  function span(id) {
    return spanFor ? spanFor(id) : 1
  }

  // Keeps the visual order in step with the model: new ids join at the end,
  // departed ones drop out, and everything else keeps the place the user put it.
  function syncOrder() {
    var next = []
    for (var i = 0; i < order.length; i++)
      if (ids.indexOf(order[i]) !== -1 && next.indexOf(order[i]) === -1) next.push(order[i])
    for (var j = 0; j < ids.length; j++)
      if (next.indexOf(ids[j]) === -1) next.push(ids[j])
    order = next
    scheduleRelayout()
  }

  function relayout() {
    var items = []
    for (var i = 0; i < order.length; i++) {
      var slot = slots[order[i]]
      items.push({ span: root.span(order[i]), height: slot ? slot.height : 0 })
    }
    var result = Pack.pack(items, columns, columnWidth, spacing)
    var map = ({})
    for (var j = 0; j < order.length; j++) map[order[j]] = result.boxes[j]
    boxById = map
    boxList = result.boxes
    packedHeight = result.height
  }

  // Heights settle over several frames as content loads, and every change would
  // otherwise re-pack everything. A zero interval timer coalesces them into one
  // pass, and belongs to this item so it stops when the layout is torn down.
  function scheduleRelayout() {
    relayoutTimer.restart()
  }

  function moveDragged(x, y) {
    if (draggingId === "") return
    var from = order.indexOf(draggingId)
    var over = Pack.boxAt(boxList, x, y)
    if (over < 0 || over === from) return
    order = Pack.move(order, from, over)
    relayout()
  }

  function endDrag() {
    if (draggingId === "") return
    draggingId = ""
    orderRequested(order.slice())
  }

  onIdsChanged: syncOrder()
  onColumnsChanged: scheduleRelayout()
  onColumnWidthChanged: scheduleRelayout()
  onSpacingChanged: scheduleRelayout()
  Component.onCompleted: syncOrder()

  Timer {
    id: relayoutTimer
    interval: 0
    repeat: false
    onTriggered: root.relayout()
  }

  Repeater {
    id: repeater
    model: root.ids

    Item {
      id: slot

      readonly property string cardId: modelData
      readonly property var box: root.boxById[cardId]
      readonly property bool dragging: root.draggingId === cardId
      property real dragX: 0
      property real dragY: 0

      width: box ? box.width : root.columnWidth * root.span(cardId)
      height: content.item ? content.item.implicitHeight : 0
      x: dragging ? dragX : (box ? box.x : 0)
      y: dragging ? dragY : (box ? box.y : 0)
      z: dragging ? 10 : 0
      opacity: dragging ? 0.85 : 1

      // The reflow is animated, so a card that moves out from under a dragged
      // one is visibly the same card rather than a jump cut.
      Behavior on x { enabled: !slot.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }
      Behavior on y { enabled: !slot.dragging; NumberAnimation { duration: 170; easing.type: Easing.OutCubic } }

      onHeightChanged: root.scheduleRelayout()
      Component.onCompleted: root.registerSlot(cardId, slot)
      Component.onDestruction: root.unregisterSlot(cardId)

      Loader {
        id: content
        width: slot.width
        sourceComponent: root.delegate
        // Read by the delegate, which is defined by whoever set `delegate`.
        readonly property string cardId: slot.cardId
        readonly property bool selected: root.selectedId === slot.cardId
      }

      TapHandler {
        enabled: root.arrangeable
        // Only fires when nothing inside the card took the press, so the
        // profile buttons and the media transport keep working.
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.selectRequested(slot.cardId)
      }

      DragHandler {
        enabled: root.arrangeable
        target: null
        onActiveChanged: {
          if (active) {
            slot.dragX = slot.x
            slot.dragY = slot.y
            root.draggingId = slot.cardId
          } else {
            root.endDrag()
          }
        }
        onCentroidChanged: {
          if (!active) return
          slot.dragX = slot.x + centroid.position.x - centroid.pressPosition.x
          slot.dragY = slot.y + centroid.position.y - centroid.pressPosition.y
          root.moveDragged(slot.dragX + slot.width / 2, slot.dragY + slot.height / 2)
        }
      }
    }
  }
}
