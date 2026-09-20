import QtQuick
import "model/Layout.js" as Layout

// Full-size cards in a grid. The default arrangement, and what the overlay
// always uses.
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

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  Grid {
    id: grid
    columns: root.columnCount
    spacing: root.settings.spacing
    // Cards differ in height, so rows align on their top edge rather than
    // stretching the short ones to match the tall one.
    verticalItemAlignment: Grid.AlignTop

    Repeater {
      model: root.cards

      Loader {
        readonly property string cardId: modelData
        width: root.settings.cardWidth
        height: item ? item.implicitHeight : 0

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
  }

  Component {
    id: systemComponent
    SystemCard { width: root.settings.cardWidth; backgroundOpacity: root.settings.opacity
      system: root.system; gpuService: root.gpuService; config: root.settings }
  }

  Component {
    id: podsComponent
    PodsCard { width: root.settings.cardWidth; backgroundOpacity: root.settings.opacity
      pods: root.pods; config: root.settings }
  }

  Component {
    id: batteryComponent
    BatteryCard { width: root.settings.cardWidth; backgroundOpacity: root.settings.opacity
      power: root.power; config: root.settings }
  }

  Component {
    id: powerComponent
    PowerCard { width: root.settings.cardWidth; backgroundOpacity: root.settings.opacity
      power: root.power; config: root.settings
      onProfileRequested: function (profile) { root.profileRequested(profile) } }
  }

  Component {
    id: mediaComponent
    MediaCard { width: root.settings.cardWidth; backgroundOpacity: root.settings.opacity
      media: root.media; config: root.settings }
  }
}
