import QtQuick
import qs.Commons
import qs.Ui
import "../ui"
import "../model/DateTime.js" as DateTime
import "../model/Format.js" as Format
import "../model/TodoList.js" as TodoList

// One to-do: a box to tick, the text, and how close its deadline is.
Item {
  id: root

  property var todo: null
  property int now: 0
  property bool archivable: true
  // Only offered in the archive, where putting a to-do back is the other
  // option: deleting is the one action here that cannot be undone, so it is
  // never one mis-tap away from a list you are working through.
  property bool deletable: false
  property var config: ({})

  signal toggled()
  signal archiveToggled()
  signal deleteRequested()

  readonly property string urgency: TodoList.urgency(todo, now > 0 ? now : Date.now())
  readonly property color accent: TodoColors.forUrgency(urgency)
  readonly property bool done: !!todo && todo.done === true
  readonly property bool archived: !!todo && todo.archived === true

  // A time today, a weekday this week, a date beyond that — in whichever date
  // and clock format the user chose.
  readonly property string deadlineLabel: DateTime.deadlineLabel(
    todo ? todo.deadline : 0, now, config.dateFormat, config.timeFormat)

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(box.height, label.implicitHeight)

  // The urgency stripe. A colour alone would be lost on anyone who cannot tell
  // these four apart, so the words next to it say the same thing.
  Rectangle {
    id: stripe
    anchors.left: parent.left
    anchors.verticalCenter: parent.verticalCenter
    width: Math.max(2, Style.space(3))
    height: parent.height - Style.spacing.xxs
    radius: width / 2
    color: root.accent
    opacity: root.urgency === TodoList.NONE ? 0.35 : 1
  }

  BorderSurface {
    id: box
    anchors.left: stripe.right
    anchors.leftMargin: Style.spacing.md
    anchors.verticalCenter: parent.verticalCenter
    width: Style.space(16)
    height: width
    radius: Style.cornerRadius > 0 ? Math.max(3, Style.space(4)) : 0
    color: root.done ? Util.alpha(root.accent, 0.9) : "transparent"
    borderSpec: Border.flat(root.done ? root.accent : Util.alpha(Color.popups.text, 0.45), 1)

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      visible: root.done
      text: "󰄬"
      color: Color.popups.background
      font.family: Style.font.family
      font.pixelSize: parent.width * 0.78
    }

    MouseArea {
      anchors.fill: parent
      anchors.margins: -Style.spacing.xs
      cursorShape: Qt.PointingHandCursor
      onClicked: root.toggled()
    }
  }

  Column {
    id: label
    anchors.left: box.right
    anchors.leftMargin: Style.spacing.md
    anchors.right: rowActions.left
    anchors.rightMargin: Style.spacing.xs
    anchors.verticalCenter: parent.verticalCenter
    spacing: 0

    Text {
      textFormat: Text.PlainText
      width: parent.width
      // A to-do's text comes from a file this plugin writes but anyone can edit,
      // so it is plain text and elided, never interpreted.
      text: root.todo ? root.todo.text : ""
      color: root.done ? Qt.darker(Color.popups.text, 1.6) : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.strikeout: root.done
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.deadlineLabel !== "" || TodoColors.label(root.urgency) !== ""
      text: Format.joinMeta([root.deadlineLabel, TodoColors.label(root.urgency)])
      color: root.urgency === TodoList.NONE || root.done
        ? Qt.darker(Color.popups.text, 1.5) : root.accent
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  Row {
    id: rowActions
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.xxs

    PanelActionButton {
      visible: root.archivable
      iconText: root.archived ? "󰦛" : "󱉙"
      tooltipText: root.archived ? "Bring back" : "Archive"
      foreground: Qt.darker(Color.popups.text, 1.4)
      fontSize: Style.font.bodySmall
      size: Style.space(20)
      onClicked: root.archiveToggled()
    }

    PanelActionButton {
      visible: root.deletable
      iconText: "󰩹"
      tooltipText: "Delete for good"
      foreground: Qt.darker(Color.popups.text, 1.4)
      fontSize: Style.font.bodySmall
      size: Style.space(20)
      onClicked: root.deleteRequested()
    }
  }
}
