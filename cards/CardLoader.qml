import QtQuick
import "../model/Layout.js" as Layout

// One full card, chosen by id, with everything it reads and every intent it
// raises wired once. Shared by the column layout and the tile grid, so both
// draw the same cards with the same bindings.
//
// In the grid a card is a fixed-size tile: `tileHeight` sets its height, and
// the two short tiles take the cards' compact look to fit. Left at -1, a card is
// as tall as its content, which is what the columns want.
Loader {
  id: root

  property string cardId: ""
  property bool selected: false
  property var settings: null
  property bool arrangeable: false
  property bool inGrid: false
  property real tileHeight: -1
  // Whatever raises selectRequested(id) for this layout, so the to-do composer
  // can close when another widget is tapped.
  property var selectionSource: null

  property var system: null
  property var gpuService: null
  property var pods: null
  property var power: null
  property var media: null
  property var todos: null

  signal hideRequested(string id)
  signal profileRequested(string profile)
  signal composingChanged(bool active)

  // What the card would like, whatever it is drawn at: the grid reads this to
  // size its cells.
  readonly property real naturalHeight: item ? item.implicitHeight : 0

  sourceComponent: {
    if (cardId === Layout.CARD_SYSTEM) return systemComponent
    if (cardId === Layout.CARD_PODS) return podsComponent
    if (cardId === Layout.CARD_BATTERY) return batteryComponent
    if (cardId === Layout.CARD_POWER) return powerComponent
    if (cardId === Layout.CARD_MEDIA) return mediaComponent
    if (cardId === Layout.CARD_TODO) return todoComponent
    return null
  }

  // Bound on the item rather than on each card, so all six share one rule.
  Binding {
    target: root.item
    property: "height"
    value: root.tileHeight
    when: root.item !== null && root.tileHeight > 0
  }

  Component {
    id: systemComponent
    SystemCard { width: root.width; backgroundOpacity: root.settings.opacity
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      system: root.system; gpuService: root.gpuService; config: root.settings }
  }

  Component {
    id: podsComponent
    PodsCard { width: root.width; backgroundOpacity: root.settings.opacity
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      pods: root.pods; config: root.settings }
  }

  Component {
    id: batteryComponent
    BatteryCard { width: root.width; backgroundOpacity: root.settings.opacity
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      power: root.power; config: root.settings }
  }

  Component {
    id: powerComponent
    PowerCard { width: root.width; backgroundOpacity: root.settings.opacity
      compact: root.inGrid
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      power: root.power; config: root.settings
      onProfileRequested: function (profile) { root.profileRequested(profile) } }
  }

  Component {
    id: todoComponent
    TodoCard { id: todoCard
      width: root.width; backgroundOpacity: root.settings.opacity
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      todos: root.todos; config: root.settings
      // In the grid the tile is a fixed height and the list scrolls inside it.
      fixedHeight: root.inGrid ? root.tileHeight : -1

      // A tap on any other widget is also a way of saying "never mind": the
      // composer closes and the desktop gives the keyboard back, the same as
      // clicking off the cards entirely. In `resources` because a card's default
      // property is its visible content, and this is not content.
      resources: Connections {
        target: root.selectionSource
        ignoreUnknownSignals: true
        function onSelectRequested(id) {
          if (id !== Layout.CARD_TODO) todoCard.composerOpen = false
        }
      }
      // The overlay and the popup already have a keyboard, so the composer is
      // simply there. The desktop asks first — see DesktopSurface.
      editable: !root.arrangeable
      requestable: root.arrangeable
      onComposingChanged: function (active) { root.composingChanged(active) } }
  }

  Component {
    id: mediaComponent
    MediaCard { width: root.width; backgroundOpacity: root.settings.opacity
      compact: root.inGrid
      selected: root.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(root.cardId)
      media: root.media; config: root.settings }
  }
}
