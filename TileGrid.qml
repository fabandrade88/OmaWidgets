import QtQuick
import "model/Format.js" as Format
import "model/Layout.js" as Layout
import "model/Power.js" as Power

// Compact tiles on the desktop: one per card, packed and arrangeable, with the
// Performance tile spanning two columns.
PackedLayout {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  property var settings: null
  property var presence: Layout.defaultState()

  signal profileRequested(string profile)

  readonly property int side: settings.tileSize

  ids: Layout.visibleCards(settings, presence)
  columns: Math.min(settings.columns, Math.max(1, ids.length))
  columnWidth: side
  spacing: settings.spacing
  spanFor: function (id) { return Layout.tileSpan(id) }

  delegate: Component {
    Loader {
      readonly property string cardId: parent ? parent.cardId : ""
      readonly property bool selected: parent ? parent.selected : false

      width: parent ? parent.width : 0
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

  component BaseTile: Tile {
    width: parent.width
    height: root.side
    radius: root.settings.tileRadius
    backgroundOpacity: root.settings.opacity
    selected: parent.selected
  }

  Component {
    id: systemComponent
    SystemTile {
      width: parent.width
      height: root.side
      radius: root.settings.tileRadius
      backgroundOpacity: root.settings.opacity
      selected: parent.selected
      system: root.system
      gpuService: root.gpuService
      config: root.settings
    }
  }

  Component {
    id: podsComponent
    PodsTile {
      width: parent.width
      height: root.side
      radius: root.settings.tileRadius
      backgroundOpacity: root.settings.opacity
      selected: parent.selected
      pods: root.pods
      config: root.settings
    }
  }

  Component {
    id: batteryComponent
    BaseTile {
      glyph: root.power.icon
      label: Layout.tileLabel(Layout.CARD_BATTERY)
      value: root.power.present ? Format.percent(root.power.fraction) : "—"
      caption: Format.duration(root.power.secondsRemaining)
        || (root.power.charging ? "charging" : "")
      fraction: root.power.present ? root.power.fraction : -1
      alert: root.power.low
    }
  }

  Component {
    id: powerComponent
    BaseTile {
      glyph: Power.profileIcon(root.power.activeProfile)
      label: Layout.tileLabel(Layout.CARD_POWER)
      value: Power.profileLabel(root.power.activeProfile) || "—"
      caption: root.power.onBattery ? "on battery" : "on AC"
      // The ring shows where this profile sits on the saver-to-performance
      // scale, so the tile carries what the segmented control does on the card.
      fraction: {
        var at = root.power.profiles.indexOf(root.power.activeProfile)
        if (at < 0 || root.power.profiles.length < 2) return -1
        return at / (root.power.profiles.length - 1)
      }
      // Arranging comes first: on the desktop a tap selects, and only a tap on
      // the already-selected tile cycles the profile. Nothing is selectable in
      // the overlay, so there it acts on the first tap as before.
      interactive: root.power.profilesAvailable && (!root.arrangeable || parent.selected)
      onActivated: root.power.cycleProfile(1)
    }
  }

  Component {
    id: mediaComponent
    MediaTile {
      activatable: !root.arrangeable || parent.selected
      width: parent.width
      height: root.side
      radius: root.settings.tileRadius
      backgroundOpacity: root.settings.opacity
      selected: parent.selected
      media: root.media
      config: root.settings
    }
  }
}
