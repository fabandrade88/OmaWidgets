import QtQuick
import qs.Commons
import qs.Ui
import "../ui"
import "../model/Pomodoro.js" as Pomodoro

// The Pomodoro clock: a ring that fills as the phase runs, the time left inside
// it, and the three phases as one segmented control underneath.
//
// Phases are picked, not cycled through: a break is a choice rather than the
// next item in a queue, and "the long one, now" should not take three taps. The
// phase showing is the segment highlighted, and pressing it starts or pauses —
// so the three buttons are the transport as well.
Item {
  id: root

  property var todos: null
  property real ringSize: Style.space(76)
  property bool compact: false

  readonly property string remaining: todos ? todos.remainingLabel : "25:00"
  readonly property real progress: todos ? todos.phaseProgress : 0
  readonly property bool running: !!todos && todos.running
  readonly property int rounds: todos ? todos.completedFocus : 0
  readonly property string phase: todos ? todos.phase : Pomodoro.FOCUS
  readonly property bool focusing: phase === Pomodoro.FOCUS
  readonly property var timing: todos ? todos.timing : Pomodoro.DEFAULTS

  // A break is a different activity, so it is a different colour. Focus borrows
  // the theme's accent like every other ring in the plugin.
  readonly property color accent: focusing ? Color.accent : TodoColors.done
  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  readonly property var phases: [
    { id: Pomodoro.FOCUS, glyph: "󱎫", minutes: timing.focusMinutes },
    { id: Pomodoro.SHORT_BREAK, glyph: "󰅶", minutes: timing.shortBreakMinutes },
    { id: Pomodoro.LONG_BREAK, glyph: "󰒲", minutes: timing.longBreakMinutes }
  ]

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

      // Only the clock goes inside the ring. The phase name used to sit under
      // it, where "Short break" was wider than the ring it was centred in — and
      // the segments below now say which phase this is anyway.
      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: root.remaining
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: root.compact ? Style.font.subtitle : Style.font.heading
        font.bold: true
      }
    }

    Row {
      id: segments
      width: parent.width
      visible: !root.compact
      spacing: Style.spacing.xs

      Repeater {
        model: root.phases

        BorderSurface {
          id: segment

          readonly property bool isActive: modelData.id === root.phase
          readonly property bool hot: mouse.containsMouse

          width: (segments.width - Style.spacing.xs * 2) / 3
          implicitHeight: Math.max(Style.spacing.controlHeight,
            inside.implicitHeight + Style.spacing.sm * 2)
          radius: Style.cornerRadius
          color: isActive ? Style.selectedAccentFill : (hot ? Style.hoverFill : Style.normalFill)
          borderSpec: Border.controlSpec(isActive ? "selected" : (hot ? "hover" : "normal"),
            root.foreground, root.accent, Color.urgent)

          Column {
            id: inside
            anchors.centerIn: parent
            spacing: Style.space(1)

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              // The phase showing says whether it is running; the other two say
              // what they are.
              text: segment.isActive ? (root.running ? "󰏤" : "󰐊") : modelData.glyph
              color: segment.isActive ? root.accent : (segment.hot ? root.foreground : root.dim)
              font.family: Style.font.family
              font.pixelSize: Style.font.bodySmall
            }

            Text {
              textFormat: Text.PlainText
              anchors.horizontalCenter: parent.horizontalCenter
              text: modelData.minutes + "m"
              color: segment.isActive ? root.foreground : root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
              font.bold: segment.isActive
            }
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: if (root.todos) root.todos.startPhase(modelData.id)
          }
        }
      }
    }

    Row {
      anchors.horizontalCenter: parent.horizontalCenter
      visible: !root.compact && (root.rounds > 0 || root.progress > 0)
      spacing: Style.spacing.xs

      Text {
        anchors.verticalCenter: parent.verticalCenter
        textFormat: Text.PlainText
        text: root.rounds + (root.rounds === 1 ? " round done" : " rounds done")
        color: root.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
      }

      PanelActionButton {
        anchors.verticalCenter: parent.verticalCenter
        visible: root.progress > 0
        iconText: "󰑐"
        tooltipText: "Restart this phase"
        foreground: Qt.darker(root.foreground, 1.4)
        fontSize: Style.font.bodySmall
        size: Style.space(20)
        onClicked: if (root.todos) root.todos.resetPhase()
      }
    }
  }
}
