import QtQuick
import qs.Commons
import "model/TodoList.js" as TodoList

// The to-do tile: the Pomodoro ring, and what is left to do under it.
//
// A tile has room for one number, and the number worth having is the clock —
// the list is what the card is for. The ring's colour still follows the most
// pressing deadline, so the tile says "something is late" without listing it.
Tile {
  id: root

  property var todos: null
  property var config: ({})
  property bool activatable: true

  readonly property var counts: todos ? todos.counts : ({ open: 0, done: 0, total: 0, archived: 0 })
  readonly property string worst: todos ? todos.worstUrgency : TodoList.NONE
  readonly property bool running: !!todos && todos.running

  glyph: ""
  value: todos ? todos.remainingLabel : "25:00"
  caption: counts.open > 0
    ? counts.open + (counts.open === 1 ? " to do" : " to do")
    : (todos && todos.running ? todos.phaseLabel.toLowerCase() : "all clear")
  fraction: todos ? todos.phaseProgress : -1
  alert: worst === TodoList.OVERDUE
  // Tapping starts and pauses the clock, which is the one gesture a tile has
  // room for. Ticking things off is the card's job.
  interactive: activatable
  onActivated: if (todos) todos.toggleRunning()

  // A dot in the corner for the most pressing deadline, since the ring is
  // already saying something else.
  Rectangle {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.margins: Style.spacing.md
    width: Math.max(6, Style.space(7))
    height: width
    radius: width / 2
    visible: root.worst !== TodoList.NONE && root.worst !== TodoList.DONE
    color: TodoColors.forUrgency(root.worst)
  }

  // A paused clock is worth distinguishing from a running one at a glance.
  Text {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: Style.spacing.md
    textFormat: Text.PlainText
    visible: !root.running
    text: "󰏤"
    color: Qt.darker(Color.popups.text, 1.5)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
  }
}
