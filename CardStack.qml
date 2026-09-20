import QtQuick
import "model/Settings.js" as Settings

// The arrangement of cards, shared by the desktop surface and the overlay so the
// two can never drift apart. Card order is the user's; which cards exist, and
// whether one is worth drawing right now, is decided here.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  property var config: Settings.DEFAULTS

  signal profileRequested(string profile)

  // Normalised on the way in, so a caller that is still being constructed (or a
  // hand-edited shell.json) yields the defaults rather than a broken binding.
  readonly property var settings: Settings.normalize(config)
  readonly property var visibleCards: Settings.visibleCards(settings, !!(pods && pods.hasBattery))

  readonly property int cardWidth: settings.cardWidth
  readonly property int columnCount: Math.min(settings.columns, Math.max(1, visibleCards.length))

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
      model: root.visibleCards

      Loader {
        id: slot
        readonly property string cardId: modelData
        width: root.cardWidth
        height: item ? item.implicitHeight : 0
        asynchronous: false

        sourceComponent: {
          if (cardId === Settings.CARD_SYSTEM) return systemComponent
          if (cardId === Settings.CARD_PODS) return podsComponent
          if (cardId === Settings.CARD_BATTERY) return batteryComponent
          if (cardId === Settings.CARD_POWER) return powerComponent
          return null
        }
      }
    }
  }

  Component {
    id: systemComponent
    SystemCard {
      width: root.cardWidth
      system: root.system
      gpuService: root.gpuService
      config: root.settings
      compact: root.settings.compact
      backgroundOpacity: root.settings.opacity
    }
  }

  Component {
    id: podsComponent
    PodsCard {
      width: root.cardWidth
      pods: root.pods
      config: root.settings
      compact: root.settings.compact
      backgroundOpacity: root.settings.opacity
    }
  }

  Component {
    id: batteryComponent
    BatteryCard {
      width: root.cardWidth
      power: root.power
      config: root.settings
      compact: root.settings.compact
      backgroundOpacity: root.settings.opacity
    }
  }

  Component {
    id: powerComponent
    PowerCard {
      width: root.cardWidth
      power: root.power
      config: root.settings
      compact: root.settings.compact
      backgroundOpacity: root.settings.opacity
      onProfileRequested: function (profile) { root.profileRequested(profile) }
    }
  }
}
