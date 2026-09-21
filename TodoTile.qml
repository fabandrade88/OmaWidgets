import QtQuick
import qs.Commons
import "model/TodoList.js" as TodoList

// The to-do tile: the Pomodoro clock in the ring, and what is left to do under
// it.
//
// The clock goes inside the ring rather than under it, the way the card's dial
// reads and the way a clock is drawn. An earlier version put the time where the
// other tiles put their number and the running state in a corner, which left a
// pause glyph floating with nothing to attach itself to.
Tile {
  id: root

  property var todos: null
  property var config: ({})
  property bool activatable: true

  readonly property var counts: todos ? todos.counts : ({ open: 0, done: 0, total: 0, archived: 0 })
  readonly property string worst: todos ? todos.worstUrgency : TodoList.NONE
  readonly property bool running: !!todos && todos.running
  readonly property bool focusing: !todos || todos.phase === "focus"

  // A break is a different activity, so it is a different colour — the same
  // pairing the card's dial uses.
  readonly property color ringColor: alert
    ? Color.urgent : (focusing ? Color.accent : TodoColors.done)

  // Tile's own glyph-in-a-ring is replaced by the clock below.
  glyph: ""
  value: ""
  caption: counts.open > 0
    ? counts.open + (counts.open === 1 ? " to do" : " to do")
    : (root.running ? todos.phaseLabel.toLowerCase() : "all clear")
  fraction: -1
  alert: worst === TodoList.OVERDUE
  // Tapping starts and pauses the clock, which is the one gesture a tile has
  // room for. Ticking things off is the card's job.
  interactive: activatable
  onActivated: if (todos) todos.toggleRunning()

  artwork: Component {
    IconRing {
      value: root.todos ? root.todos.phaseProgress : -1
      fill: root.ringColor

      Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
          textFormat: Text.PlainText
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.todos ? root.todos.remainingLabel : "25:00"
          color: root.alert ? Color.urgent : Color.popups.text
          font.family: Style.font.family
          font.pixelSize: Style.font.subtitle
          font.bold: true
        }

        // The running state belongs with the clock it describes, not in a
        // corner of the tile.
        Text {
          textFormat: Text.PlainText
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.running ? "󰏤" : "󰐊"
          color: Qt.darker(Color.popups.text, 1.5)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
        }
      }
    }
  }

  // A dot for the most pressing deadline, since the ring is saying something
  // else.
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
}
