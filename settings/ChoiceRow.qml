import QtQuick
import qs.Commons
import qs.Ui

// A labelled row of mutually exclusive options, for settings with a handful of
// named choices rather than a number or a switch.
Column {
  id: root

  property string label: ""
  property string description: ""
  // [{ value, label }]
  property var options: []
  property string current: ""

  signal picked(string value)

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  spacing: Style.spacing.xs

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

  Flow {
    width: parent.width
    spacing: Style.spacing.xs

    Repeater {
      model: root.options

      BorderSurface {
        id: option

        readonly property bool isCurrent: modelData.value === root.current
        readonly property bool hot: mouse.containsMouse

        implicitWidth: optionLabel.implicitWidth + Style.spacing.md * 2
        implicitHeight: Math.max(Style.spacing.controlHeight,
          optionLabel.implicitHeight + Style.spacing.sm * 2)
        radius: Style.cornerRadius
        color: isCurrent ? Style.selectedAccentFill : (hot ? Style.hoverFill : Style.normalFill)
        borderSpec: Border.controlSpec(isCurrent ? "selected" : (hot ? "hover" : "normal"),
          root.foreground, Color.accent, Color.urgent)

        Text {
          id: optionLabel
          textFormat: Text.PlainText
          anchors.centerIn: parent
          text: modelData.label
          color: option.isCurrent ? root.foreground : root.dim
          font.family: Style.font.family
          font.pixelSize: Style.font.caption
          font.bold: option.isCurrent
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(modelData.value)
        }
      }
    }
  }
}
