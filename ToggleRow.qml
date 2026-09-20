import QtQuick
import qs.Commons
import qs.Ui

// A labelled switch, for the on/off settings in the bar popup.
Item {
  id: root

  property string label: ""
  property string description: ""
  property bool checked: false
  property bool interactive: true
  property bool hasCursor: false

  signal toggled()

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(toggle.implicitHeight, labels.implicitHeight)

  Column {
    id: labels
    anchors.left: parent.left
    anchors.right: toggle.left
    anchors.rightMargin: Style.spacing.md
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.space(1)

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.label
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.description !== ""
      text: root.description
      color: root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      wrapMode: Text.WordWrap
    }
  }

  ToggleSwitch {
    id: toggle
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    checked: root.checked
    interactive: root.interactive
    hasCursor: root.hasCursor
    foreground: root.foreground
    onToggled: root.toggled()
  }
}
