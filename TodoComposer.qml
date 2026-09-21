import QtQuick
import qs.Commons
import qs.Ui
import "model/DateTime.js" as DateTime
import "model/Todo.js" as Todo

// Adding a to-do: the text, and optionally when it is due.
//
// Only shown where the keyboard reaches. The desktop layer never takes focus —
// that is what keeps a desktop widget from stealing keys from the window you are
// working in — so new to-dos are added from the bar popup or the overlay, and
// the desktop card ticks them off.
Column {
  id: root

  property bool busy: false
  property var config: ({})

  readonly property string dateFormat: DateTime.dateFormat(config.dateFormat)
  readonly property string timeFormat: DateTime.timeFormat(config.timeFormat)

  signal submitted(string text, real deadline)
  signal dismissed()

  // Focused as soon as it appears, so asking to add a to-do puts the cursor
  // where the to-do goes.
  onVisibleChanged: if (visible) textField.forceActiveFocus()

  // Parsed from the two fields rather than a date picker: a picker is a lot of
  // widget for something most to-dos do not have at all.
  // Parsed by the plugin rather than by Qt's locale parser, so what the field
  // accepts follows the setting rather than whatever locale the session has.
  readonly property var dayParts: DateTime.parseDate(dayField.text, dateFormat)
  readonly property var timeParts: DateTime.parseTime(timeField.text, timeFormat)
  readonly property real deadline: DateTime.toTimestamp(dayParts, timeParts)

  readonly property bool dayValid: dayField.text.trim() === "" || dayParts !== null
  readonly property bool timeValid: timeParts !== null
  readonly property bool canSubmit: Todo.text(textField.text) !== "" && dayValid && timeValid

  function submit() {
    if (!canSubmit) return
    root.submitted(textField.text, root.deadline)
    textField.text = ""
    dayField.text = ""
    timeField.text = ""
    // Only worth taking the cursor back if the field is still here to take it.
    if (visible) textField.forceActiveFocus()
  }

  spacing: Style.spacing.sm

  TextField {
    id: textField
    width: parent.width
    placeholderText: "Add a to-do"
    foreground: Color.popups.text
    onAccepted: root.submit()
    Keys.onEscapePressed: root.dismissed()
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm

    TextField {
      id: dayField
      width: (parent.width - addButton.width - parent.spacing * 2) * 0.58
      placeholderText: DateTime.datePlaceholder(root.dateFormat)
      foreground: root.dayValid ? Color.popups.text : Color.urgent
      onAccepted: root.submit()
    }

    TextField {
      id: timeField
      width: (parent.width - addButton.width - parent.spacing * 2) * 0.42
      placeholderText: DateTime.timePlaceholder(root.timeFormat)
      foreground: root.timeValid ? Color.popups.text : Color.urgent
      onAccepted: root.submit()
    }

    PanelActionButton {
      id: addButton
      anchors.verticalCenter: parent.verticalCenter
      iconText: "󰐕"
      tooltipText: "Add"
      foreground: Color.popups.text
      bordered: true
      enabled: root.canSubmit && !root.busy
      opacity: enabled ? 1 : 0.4
      onClicked: root.submit()
    }
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: !root.dayValid || !root.timeValid
    text: "Date like " + DateTime.datePlaceholder(root.dateFormat)
      + ", time like " + DateTime.timePlaceholder(root.timeFormat) + "."
    color: Color.urgent
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
