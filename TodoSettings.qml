import QtQuick
import qs.Commons

// The Pomodoro durations. 25/5/15 every four rounds is the convention this
// starts from, and all four are editable because it is a convention.
Column {
  id: root

  required property var config

  signal timingChanged(string key, int value)

  readonly property color foreground: Color.popups.text

  spacing: Style.spacing.md

  StepperRow {
    width: parent.width
    label: "Focus"
    value: root.config.focusMinutes
    minimum: 1
    maximum: 180
    step: 5
    suffix: "m"
    onChanged: function (value) { root.timingChanged("focusMinutes", value) }
  }

  StepperRow {
    width: parent.width
    label: "Short break"
    value: root.config.shortBreakMinutes
    minimum: 1
    maximum: 60
    suffix: "m"
    onChanged: function (value) { root.timingChanged("shortBreakMinutes", value) }
  }

  StepperRow {
    width: parent.width
    label: "Long break"
    value: root.config.longBreakMinutes
    minimum: 1
    maximum: 120
    step: 5
    suffix: "m"
    onChanged: function (value) { root.timingChanged("longBreakMinutes", value) }
  }

  StepperRow {
    width: parent.width
    label: "Long break every"
    description: "Focus rounds before the longer break."
    value: root.config.longBreakEvery
    minimum: 1
    maximum: 12
    onChanged: function (value) { root.timingChanged("longBreakEvery", value) }
  }

  StepperRow {
    width: parent.width
    label: "To-dos shown"
    description: "How many rows the card lists before summarising the rest."
    value: root.config.todoRows
    minimum: 1
    maximum: 20
    onChanged: function (value) { root.timingChanged("todoRows", value) }
  }
}
