import QtQuick
import qs.Commons
import qs.Ui
import "../model/Format.js" as Format
import "../model/TodoList.js" as TodoList

// The to-do card: a Pomodoro clock and the list it is for.
//
// The two belong on one card because they are one activity — you run a focus
// round *at* something. The clock is on top, the list under it, and the list is
// sorted by how nearly late each item is.
Card {
  id: root

  property var todos: null
  property var config: ({})
  // Adding needs a keyboard, and the desktop layer never takes one. True in the
  // overlay and the bar popup, false on the desktop.
  // Where a keyboard is already available — the overlay and the bar popup — the
  // composer is simply shown. On the desktop it is behind a button, because
  // showing it there means taking the keyboard from the window you are using.
  property bool editable: false
  property bool requestable: false
  property bool showArchive: false
  property bool composerOpen: false

  signal composingChanged(bool active)

  onComposerOpenChanged: root.composingChanged(composerOpen)

  // The archive is a different list, not a place to add to: opening it puts the
  // composer away, and the keyboard with it.
  onShowArchiveChanged: if (showArchive) composerOpen = false

  readonly property bool composerVisible: (editable || composerOpen) && !showArchive

  readonly property var counts: todos ? todos.counts : ({ open: 0, done: 0, total: 0, archived: 0 })
  readonly property string worst: todos ? todos.worstUrgency : TodoList.NONE
  readonly property var shown: {
    if (!todos) return []
    return showArchive ? todos.archivedItems : todos.sorted
  }
  readonly property int visibleLimit: config.todoRows || 5

  title: "To-do"
  glyph: "󰗇"
  // The card's accent follows the most pressing deadline in it, so a glance at
  // the desktop says whether anything needs attention.
  alert: worst === TodoList.OVERDUE
  meta: Format.joinMeta([
    counts.open > 0 ? counts.open + " open" : "all clear",
    counts.done > 0 ? counts.done + " done" : "",
    todos && todos.running ? todos.phaseLabel.toLowerCase() : ""
  ])

  PomodoroDial {
    anchors.horizontalCenter: parent.horizontalCenter
    todos: root.todos
    ringSize: Style.space(78)
  }

  PanelSeparator { width: parent.width }

  Column {
    width: parent.width
    spacing: Style.spacing.sm

    Repeater {
      model: root.shown.slice(0, root.visibleLimit)

      TodoRow {
        width: parent.width
        todo: modelData
        config: root.config
        now: root.todos ? root.todos.clock && Date.now() : 0
        deletable: root.showArchive
        onToggled: if (root.todos) root.todos.toggle(modelData.id)
        onArchiveToggled: {
          if (!root.todos) return
          if (modelData.archived === true) root.todos.unarchive(modelData.id)
          else root.todos.archive(modelData.id)
        }
        onDeleteRequested: if (root.todos) root.todos.remove(modelData.id)
      }
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.shown.length === 0
      text: root.showArchive ? "Nothing archived yet." : "Nothing to do. Enjoy it."
      color: Qt.darker(root.foreground, 1.45)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.shown.length > root.visibleLimit
      text: "+" + (root.shown.length - root.visibleLimit) + " more"
      color: Qt.darker(root.foreground, 1.45)
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
    }
  }

  // One row of actions rather than two: adding, the archive and the sweep-up
  // are the same kind of thing, and a card on the desktop should spend its
  // height on the list.
  //
  // Reading the archive needs no keyboard, so it is offered wherever the card
  // can be touched at all — the desktop layer included. Adding does need one,
  // so the + is only there when the surface can ask for it, and it stays put as
  // an X while the composer is open: clicking away closes the composer too, but
  // that depends on the surface having been given the keyboard, and a button
  // that is simply there does not.
  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    visible: root.editable || root.requestable
    spacing: Style.spacing.sm

    PanelActionButton {
      visible: root.requestable && !root.editable && !root.showArchive
      iconText: root.composerOpen ? "󰅖" : "󰐕"
      tooltipText: root.composerOpen ? "Never mind" : "Add a to-do"
      foreground: root.foreground
      bordered: true
      onClicked: root.composerOpen = !root.composerOpen
    }

    PanelActionButton {
      iconText: root.showArchive ? "󰗇" : "󱉙"
      tooltipText: root.showArchive ? "Back to the list" : "Show the archive"
      foreground: root.foreground
      bordered: true
      onClicked: root.showArchive = !root.showArchive
    }

    PanelActionButton {
      visible: !root.showArchive && root.counts.done > 0
      iconText: "󰃢"
      tooltipText: "Archive everything done"
      foreground: root.foreground
      onClicked: if (root.todos) root.todos.archiveDone()
    }
  }

  TodoComposer {
    width: parent.width
    config: root.config
    visible: root.composerVisible
    onSubmitted: function (text, deadline) {
      if (root.todos) root.todos.add(text, deadline)
      // The composer is only borrowed on the desktop — one to-do, then the card
      // goes back to its + and the keyboard goes back to your window. Where it
      // is permanent it stays put, so a list can be typed in one go.
      if (!root.editable) root.composerOpen = false
    }
    onDismissed: root.composerOpen = false
  }
}
