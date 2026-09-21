import QtQuick
import "model/Layout.js" as Layout

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
        if (cardId === Layout.CARD_TODO) return todoComponent
        return null
      }
    }
  }

  Component {
    id: systemComponent
    SystemCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      system: root.system; gpuService: root.gpuService; config: root.settings }
  }

  Component {
    id: podsComponent
    PodsCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      pods: root.pods; config: root.settings }
  }

  Component {
    id: batteryComponent
    BatteryCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      power: root.power; config: root.settings }
  }

  Component {
    id: powerComponent
    PowerCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      power: root.power; config: root.settings
      onProfileRequested: function (profile) { root.profileRequested(profile) } }
  }

  Component {
    id: todoComponent
    TodoCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      todos: root.todos; config: root.settings
      // The overlay and the popup already have a keyboard, so the composer is
      // simply there. The desktop asks first — see DesktopSurface.
      editable: !root.arrangeable
      requestable: root.arrangeable
      onComposingChanged: function (active) { root.composingChanged(active) } }
  }

  Component {
    id: mediaComponent
    MediaCard { width: root.columnWidth; backgroundOpacity: root.settings.opacity
      selected: parent.selected
      closable: root.arrangeable
      onCloseRequested: root.hideRequested(parent.cardId)
      media: root.media; config: root.settings }
  }
}
