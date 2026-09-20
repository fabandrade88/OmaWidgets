import QtQuick
import qs.Commons

// One labelled reading with its own meter: "CPU   32%  45°" over a fill bar.
Item {
  id: root

  property string label: ""
  property string value: ""
  property string detail: ""
  property real fraction: -1
  property bool alert: false
  property bool showMeter: true

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color fill: alert ? Color.urgent : Color.accent

  width: parent ? parent.width : implicitWidth
  implicitHeight: labelRow.implicitHeight + (showMeter ? meter.implicitHeight + Style.spacing.xs : 0)

  Row {
    id: labelRow
    width: parent.width
    spacing: Style.spacing.sm

    Text {
      id: labelText
      textFormat: Text.PlainText
      text: root.label
      color: root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      font.bold: true
    }

    Item {
      width: Math.max(0, parent.width - labelText.width - valueText.width - detailText.width
        - parent.spacing * (detailText.visible ? 2 : 1))
      height: 1
    }

    Text {
      id: detailText
      textFormat: Text.PlainText
      visible: root.detail !== ""
      text: root.detail
      color: root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.bodySmall
      anchors.baseline: valueText.baseline
    }

    Text {
      id: valueText
      textFormat: Text.PlainText
      text: root.value
      color: root.alert ? Color.urgent : root.foreground
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  MeterBar {
    id: meter
    visible: root.showMeter
    anchors.top: labelRow.bottom
    anchors.topMargin: Style.spacing.xs
    anchors.left: parent.left
    anchors.right: parent.right
    value: root.fraction
    fill: root.fill
  }
}
