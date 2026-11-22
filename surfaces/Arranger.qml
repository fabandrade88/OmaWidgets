import QtQuick
import "../model/Arrange.js" as Arrange
import "../model/Grid.js" as Grid
import "../model/Layout.js" as Layout

// Selecting, hiding and reordering the desktop widgets.
//
// Holds the selection, which is deliberately not persisted: a selection is a
// thing you are doing right now, not a preference. It never writes shell.json
// either — the bar widget owns the single write path — so a change to the card
// list is asked for rather than made.
QtObject {
  id: root

  property var config: ({})
  property var presence: Layout.defaultState()
  property string selectedCard: ""
  // The desktop's board in cells, reported by the surface: a keybind has no
  // pointer to say which screen it means, so the first one's answers.
  property var gridBounds: ({ cols: 0, rows: 0 })

  signal cardsChangeRequested(var cards)
  signal tilesChangeRequested(var tiles)

  readonly property var cards: config && Array.isArray(config.cards) ? config.cards : []
  // What the desktop is actually showing, which is what a selection steps
  // through — walking onto a widget hidden because nothing is playing would
  // look like the selection had vanished.
  readonly property var onScreen: Layout.visibleCards(config, presence)

  function select(id) {
    // Checked against the cards this surface actually has: `select` is an IPC
    // verb, so the id comes from whatever called it.
    selectedCard = Arrange.toggleSelection(selectedCard, id, onScreen)
  }

  function deselect() {
    selectedCard = ""
  }

  // Removes one widget from the list, which is what the X on a hovered widget
  // asks for. It comes back from the bar popup's card toggles, where the full
  // list lives — hiding here and switching it off there are the same thing.
  function hide(id) {
    var name = String(id || "")
    if (name === "" || cards.indexOf(name) === -1) return false
    if (selectedCard === name) selectedCard = ""
    cardsChangeRequested(Arrange.without(cards, name))
    return true
  }

  // Removes the selected widget from the list. It comes back from the bar
  // popup's card toggles, which is where the full list lives.
  function hideSelected() {
    if (selectedCard === "") return ""
    var hidden = selectedCard
    selectedCard = ""
    cardsChangeRequested(Arrange.without(cards, hidden))
    return hidden
  }

  // A drag finished.
  function applyOrder(ids) {
    cardsChangeRequested(Arrange.reorder(cards, ids))
  }

  // Keyboard equivalents of clicking and dragging, so the desktop can be
  // arranged from a keybind as well as with a pointer.
  function selectStep(delta) {
    selectedCard = Arrange.nextSelection(onScreen, selectedCard, delta)
    return selectedCard
  }

  function moveSelected(delta) {
    if (selectedCard === "") return false
    cardsChangeRequested(Arrange.moveBy(cards, selectedCard, delta))
    return true
  }

  // A drag on the tile grid finished.
  function applyTiles(tiles) {
    tilesChangeRequested(tiles)
  }

  // The selected tile one cell over, pushing whatever it lands on down, the
  // same as dropping it there. Says why when it does not move.
  function nudgeSelected(dc, dr) {
    if (!Layout.usesGrid(config)) return "not in grid mode"
    if (selectedCard === "") return "nothing selected"
    var tiles = config.tiles || ({})
    var cols = gridBounds.cols
    var rows = gridBounds.rows
    var layout = Grid.place(onScreen, tiles, cols, rows, config.position)
    var result = Grid.nudge(layout, selectedCard, dc, dr, cols, rows)
    if (!result || !result.fits) return "blocked"
    tilesChangeRequested(Grid.toSaved(result.layout, tiles))
    return "ok"
  }
}
