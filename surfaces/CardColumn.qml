import QtQuick
import "../cards"
import "../model/Layout.js" as Layout

// Full-size cards on the desktop, packed shortest-first and arrangeable.
PackedLayout {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  required property var todos
  property var settings: null
  property var presence: Layout.defaultState()

  signal profileRequested(string profile)

  ids: Layout.visibleCards(settings, presence)
  columns: Math.min(settings.columns, Math.max(1, ids.length))
  columnWidth: settings.cardWidth
  spacing: settings.spacing
  // Cards are one column each; only the compact Performance tile spans two.
  spanFor: function (id) { return 1 }

  delegate: Component {
    CardLoader {
      width: parent ? parent.width : 0
      cardId: parent ? parent.cardId : ""
      selected: parent ? parent.selected : false
      settings: root.settings
      arrangeable: root.arrangeable
      selectionSource: root
      system: root.system; gpuService: root.gpuService; pods: root.pods
      power: root.power; media: root.media; todos: root.todos
      onHideRequested: function (id) { root.hideRequested(id) }
      onProfileRequested: function (profile) { root.profileRequested(profile) }
      onComposingChanged: function (active) { root.composingChanged(active) }
    }
  }
}
