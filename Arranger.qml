import QtQuick
import "model/Arrange.js" as Arrange
import "model/Layout.js" as Layout

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

  signal cardsChangeRequested(var cards)

  readonly property var cards: config && Array.isArray(config.cards) ? config.cards : []
  // What the desktop is actually showing, which is what a selection steps
  // through — walking onto a widget hidden because nothing is playing would
  // look like the selection had vanished.
  readonly property var onScreen: Layout.visibleCards(config, presence)

  function select(id) {
    selectedCard = Arrange.toggleSelection(selectedCard, id)
  }

  function deselect() {
    selectedCard = ""
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
}
