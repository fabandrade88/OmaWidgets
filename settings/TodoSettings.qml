import QtQuick
import "../model/DateTime.js" as DateTime
import qs.Commons

// The Pomodoro durations. 25/5/15 every four rounds is the convention this
// starts from, and all four are editable because it is a convention.
Column {
  id: root

  required property var config

  signal timingChanged(string key, int value)
  signal formatPicked(string key, string value)
  signal flagToggled(string key)

  readonly property var dateOptions: {
    var out = []
    for (var i = 0; i < DateTime.DATE_FORMATS.length; i++) {
      var id = DateTime.DATE_FORMATS[i]
      out.push({ value: id, label: DateTime.dateLabel(id) })
    }
    return out
  }

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

  ToggleRow {
    width: parent.width
    label: "Chain the rounds"
    description: "Start the next phase by itself when one ends. Off, it waits for you."
    checked: root.config.autoAdvance
    onToggled: root.flagToggled("autoAdvance")
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

  ChoiceRow {
    width: parent.width
    label: "Date format"
    description: "How deadlines are typed and shown. Separators are interchangeable."
    options: root.dateOptions
    current: DateTime.dateFormat(root.config.dateFormat)
    onPicked: function (value) { root.formatPicked("dateFormat", value) }
  }

  ChoiceRow {
    width: parent.width
    label: "Clock"
    options: [{ value: DateTime.HOUR_24, label: "24-hour" },
      { value: DateTime.HOUR_12, label: "12-hour" }]
    current: DateTime.timeFormat(root.config.timeFormat)
    onPicked: function (value) { root.formatPicked("timeFormat", value) }
  }
}
