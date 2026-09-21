import QtQuick
import qs.Commons
import qs.Ui
import "../ui"

// The Pomodoro clock: a ring that fills as the phase runs, with the time left
// inside it and the transport underneath.
Item {
  id: root

  property var todos: null
  property real ringSize: Style.space(76)
  property bool compact: false

  readonly property string remaining: todos ? todos.remainingLabel : "25:00"
  readonly property string phaseLabel: todos ? todos.phaseLabel : "Focus"
  readonly property real progress: todos ? todos.phaseProgress : 0
  readonly property bool running: !!todos && todos.running
  readonly property int rounds: todos ? todos.completedFocus : 0
  readonly property bool focusing: !todos || todos.phase === "focus"

  // A break is a different activity, so it is a different colour. Focus borrows
  // the theme's accent like every other ring in the plugin.
  readonly property color accent: focusing ? Color.accent : TodoColors.done

  implicitWidth: ringSize
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.sm

    IconRing {
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.ringSize
      height: root.ringSize
      value: root.progress
      fill: root.accent

      Column {
        anchors.centerIn: parent
        spacing: 0

        Text {
          textFormat: Text.PlainText
          anchors.horizontalCenter: parent.horizontalCenter
          text: root.remaining
          color: Color.popups.text
          font.family: Style.font.family
          font.pixelSize: root.compact ? Style.font.subtitle : Style.font.heading
          font.bold: true
        }

        Text {
          textFormat: Text.PlainText
          anchors.horizontalCenter: parent.horizontalCenter
          visible: !root.compact
          text: root.phaseLabel.toUpperCase()
          color: Qt.darker(Color.popups.text, 1.45)
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: true
          font.letterSpacing: 0.8
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: !root.compact
      spacing: Style.spacing.sm

      PanelActionButton {
        iconText: root.running ? "󰏤" : "󰐊"
        tooltipText: root.running ? "Pause" : "Start"
        foreground: Color.popups.text
        bordered: true
        onClicked: if (root.todos) root.todos.toggleRunning()
      }

      PanelActionButton {
        iconText: "󰑐"
        tooltipText: "Restart this phase"
        foreground: Color.popups.text
        onClicked: if (root.todos) root.todos.resetPhase()
      }

      PanelActionButton {
        iconText: "󰒭"
        tooltipText: "Skip to the next phase"
        foreground: Color.popups.text
        onClicked: if (root.todos) root.todos.skip()
      }
    }

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      visible: !root.compact && root.rounds > 0
      text: root.rounds + (root.rounds === 1 ? " round done" : " rounds done")
      color: Qt.darker(Color.popups.text, 1.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
    }
  }
}
