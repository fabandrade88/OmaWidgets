import QtQuick
import "model/Layout.js" as Layout

// Full-size cards, packed into columns shortest-first.
//
// A Grid will not do here. Its rows are as tall as their tallest cell, so a
// short card beside the tall Performance card leaves a hole underneath it and
// the next card in that column starts level with the bottom of the tall one.
// Cards genuinely differ in height, so they are placed rather than tabulated:
// each one goes to whichever column is currently shortest, which is what closes
// the gap and also keeps the two columns near the same length.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  property var settings: null
  property var presence: Layout.defaultState()

  signal profileRequested(string profile)

  readonly property var cards: Layout.visibleCards(settings, presence)
  readonly property int columnCount: Math.min(settings.columns, Math.max(1, cards.length))
  readonly property int columnWidth: settings.cardWidth
  readonly property int gap: settings.spacing

  // Set by relayout(), because the height of a packed layout is only known once
  // every card has reported its own.
  property real packedHeight: 0

  implicitWidth: columnCount * columnWidth + Math.max(0, columnCount - 1) * gap
  implicitHeight: packedHeight

  function relayout() {
    var tops = []
    for (var c = 0; c < columnCount; c++) tops.push(0)

    for (var i = 0; i < repeater.count; i++) {
      var slot = repeater.itemAt(i)
      if (!slot) continue
      // Leftmost on a tie, so the order stays stable and predictable.
      var best = 0
      for (var c2 = 1; c2 < columnCount; c2++) if (tops[c2] < tops[best] - 0.5) best = c2
      slot.x = best * (columnWidth + gap)
      slot.y = tops[best]
      tops[best] += slot.height + gap
    }

    var tallest = 0
    for (var c3 = 0; c3 < columnCount; c3++) tallest = Math.max(tallest, tops[c3])
    packedHeight = Math.max(0, tallest - gap)
  }

  // Card heights settle over several frames as their content loads, and every
  // one of those changes would otherwise re-pack the whole layout. A zero
  // interval timer coalesces them into one pass.
  //
  // A timer rather than Qt.callLater: switching between the card layout and the
  // tile layout destroys this item, and a queued callLater still runs afterwards
  // — reaching for a relayout() that no longer exists. A timer belongs to the
  // item and simply stops with it.
  function scheduleRelayout() {
    relayoutTimer.restart()
  }

  Timer {
    id: relayoutTimer
    interval: 0
    repeat: false
    onTriggered: root.relayout()
  }

  onColumnCountChanged: scheduleRelayout()
  onCardsChanged: scheduleRelayout()
  onGapChanged: scheduleRelayout()
  onColumnWidthChanged: scheduleRelayout()

  Repeater {
    id: repeater
    model: root.cards

    Loader {
      readonly property string cardId: modelData
      width: root.columnWidth
      height: item ? item.implicitHeight : 0

      onHeightChanged: root.scheduleRelayout()
      Component.onCompleted: root.scheduleRelayout()

      sourceComponent: {
        if (cardId === Layout.CARD_SYSTEM) return systemComponent
        if (cardId === Layout.CARD_PODS) return podsComponent
        if (cardId === Layout.CARD_BATTERY) return batteryComponent
        if (cardId === Layout.CARD_POWER) return powerComponent
        if (cardId === Layout.CARD_MEDIA) return mediaComponent
        return null
      }
    }
  }

  Component {
    id: systemComponent
    SystemCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      system: root.system; gpuService: root.gpuService; config: root.settings }
  }

  Component {
    id: podsComponent
    PodsCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      pods: root.pods; config: root.settings }
  }

  Component {
    id: batteryComponent
    BatteryCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      power: root.power; config: root.settings }
  }

  Component {
    id: powerComponent
    PowerCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      power: root.power; config: root.settings
      onProfileRequested: function (profile) { root.profileRequested(profile) } }
  }

  Component {
    id: mediaComponent
    MediaCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      media: root.media; config: root.settings }
  }
}
