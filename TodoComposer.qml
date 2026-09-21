import QtQuick
import qs.Commons
import qs.Ui
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

  signal submitted(string text, real deadline)

  // Parsed from the two fields rather than a date picker: a picker is a lot of
  // widget for something most to-dos do not have at all.
  readonly property real deadline: {
    var day = dayField.text.trim()
    if (day === "") return 0
    var time = timeField.text.trim() === "" ? "23:59" : timeField.text.trim()
    var parsed = Date.fromLocaleString(Qt.locale(), day + " " + time, "yyyy-MM-dd HH:mm")
    return isNaN(parsed.getTime()) ? 0 : parsed.getTime()
  }

  readonly property bool dayValid: dayField.text.trim() === "" || deadline > 0
  readonly property bool canSubmit: Todo.text(textField.text) !== "" && dayValid

  function submit() {
    if (!canSubmit) return
    root.submitted(textField.text, root.deadline)
    textField.text = ""
    dayField.text = ""
    timeField.text = ""
    textField.forceActiveFocus()
  }

  spacing: Style.spacing.sm

  TextField {
    id: textField
    width: parent.width
    placeholderText: "Add a to-do"
    foreground: Color.popups.text
    onAccepted: root.submit()
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm

    TextField {
      id: dayField
      width: (parent.width - addButton.width - parent.spacing * 2) * 0.58
      placeholderText: "2026-09-30"
      foreground: root.dayValid ? Color.popups.text : Color.urgent
      onAccepted: root.submit()
    }

    TextField {
      id: timeField
      width: (parent.width - addButton.width - parent.spacing * 2) * 0.42
      placeholderText: "18:00"
      foreground: Color.popups.text
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
    visible: !root.dayValid
    text: "Date needs to look like 2026-09-30, time like 18:00."
    color: Color.urgent
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
