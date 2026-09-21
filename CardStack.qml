import QtQuick
import "model/Layout.js" as Layout
import "model/Settings.js" as Settings

// Picks the arrangement and hands both of them the same inputs, so the desktop
// surface and the overlay cannot drift apart.
//
// Compact mode is a different layout, not a smaller one: full cards give way to
// a grid of rounded squares, each showing the single number it exists for.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  property var config: Settings.DEFAULTS
  property bool arrangeable: false
  property string selectedId: ""

  signal profileRequested(string profile)
  signal selectRequested(string id)
  signal orderRequested(var ids)
  signal hideRequested(string id)

  // Normalised on the way in, so a caller that is still being constructed (or a
  // hand-edited shell.json) yields the defaults rather than a broken binding.
  readonly property var settings: Settings.normalize(config)

  // What each card's subject is reporting right now, so one that has nothing to
  // say can be left out.
  readonly property var presence: ({
    hasPods: !!(pods && pods.hasBattery),
    hasMedia: !!(media && media.hasMedia)
  })

  readonly property var visibleCards: Layout.visibleCards(settings, presence)

  implicitWidth: layout.item ? layout.item.implicitWidth : 0
  implicitHeight: layout.item ? layout.item.implicitHeight : 0

  Loader {
    id: layout
    sourceComponent: root.settings.compact ? tilesComponent : cardsComponent
  }

  Component {
    id: cardsComponent
    CardColumn {
      system: root.system; gpuService: root.gpuService; pods: root.pods
      power: root.power; media: root.media
      settings: root.settings; presence: root.presence
      arrangeable: root.arrangeable; selectedId: root.selectedId
      onProfileRequested: function (profile) { root.profileRequested(profile) }
      onSelectRequested: function (id) { root.selectRequested(id) }
      onOrderRequested: function (ids) { root.orderRequested(ids) }
      onHideRequested: function (id) { root.hideRequested(id) }
    }
  }

  Component {
    id: tilesComponent
    TileGrid {
      system: root.system; gpuService: root.gpuService; pods: root.pods
      power: root.power; media: root.media
      settings: root.settings; presence: root.presence
      arrangeable: root.arrangeable; selectedId: root.selectedId
      onProfileRequested: function (profile) { root.profileRequested(profile) }
      onSelectRequested: function (id) { root.selectRequested(id) }
      onOrderRequested: function (ids) { root.orderRequested(ids) }
      onHideRequested: function (id) { root.hideRequested(id) }
    }
  }
}
