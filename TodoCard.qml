import QtQuick
import qs.Commons
import qs.Ui
import "model/Format.js" as Format
import "model/TodoList.js" as TodoList

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
  property bool editable: false
  property bool showArchive: false

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
        now: root.todos ? root.todos.clock && Date.now() : 0
        onToggled: if (root.todos) root.todos.toggle(modelData.id)
        onArchiveToggled: {
          if (!root.todos) return
          if (modelData.archived === true) root.todos.unarchive(modelData.id)
          else root.todos.archive(modelData.id)
        }
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

  TodoComposer {
    width: parent.width
    visible: root.editable && !root.showArchive
    onSubmitted: function (text, deadline) { if (root.todos) root.todos.add(text, deadline) }
  }

  Row {
    anchors.horizontalCenter: parent.horizontalCenter
    visible: root.editable
    spacing: Style.spacing.sm

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
}
