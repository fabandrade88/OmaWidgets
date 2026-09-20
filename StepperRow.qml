import QtQuick
import qs.Commons
import qs.Ui

// A labelled number with minus and plus. For the few settings where a switch
// will not do and a text field would be overkill.
Item {
  id: root

  property string label: ""
  property string description: ""
  property int value: 1
  property int minimum: 1
  property int maximum: 6
  property int step: 1
  property string suffix: ""

  signal changed(int value)

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  function nudge(direction) {
    var next = Math.max(minimum, Math.min(maximum, value + direction * step))
    if (next !== value) root.changed(next)
  }

  width: parent ? parent.width : implicitWidth
  implicitHeight: Math.max(controls.implicitHeight, labels.implicitHeight)

  Column {
    id: labels
    anchors.left: parent.left
    anchors.right: controls.left
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

  Row {
    id: controls
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    spacing: Style.spacing.xs

    PanelActionButton {
      iconText: "󰍴"
      tooltipText: "Less"
      foreground: root.foreground
      bordered: true
      enabled: root.value > root.minimum
      opacity: enabled ? 1 : 0.35
      onClicked: root.nudge(-1)
    }

    Text {
      textFormat: Text.PlainText
      anchors.verticalCenter: parent.verticalCenter
      width: Style.space(34)
      horizontalAlignment: Text.AlignHCenter
      text: root.value + root.suffix
      color: root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }

    PanelActionButton {
      iconText: "󰐕"
      tooltipText: "More"
      foreground: root.foreground
      bordered: true
      enabled: root.value < root.maximum
      opacity: enabled ? 1 : 0.35
      onClicked: root.nudge(1)
    }
  }
}
