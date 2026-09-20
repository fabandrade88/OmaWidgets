import QtQuick
import qs.Commons

// One AirPod, the case, or a headset: a label, a level and a charging hint.
Item {
  id: root

  property string label: ""
  property var pod: null
  property bool wornHint: true

  readonly property int level: pod ? pod.level : -1
  readonly property bool known: level >= 0
  readonly property bool charging: !!pod && pod.charging === true
  readonly property bool inEar: !!pod && pod.inEar === true
  readonly property bool low: known && level <= 20 && !charging

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  width: parent ? parent.width : implicitWidth
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.xs

    Row {
      width: parent.width
      spacing: Style.spacing.sm

      Text {
        id: labelText
        textFormat: Text.PlainText
        text: root.label
        color: root.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        font.bold: true
      }

      Text {
        id: hintText
        textFormat: Text.PlainText
        // Charging wins over in-ear: it is the state that changes what the number
        // is about to do.
        visible: root.charging || (root.wornHint && root.inEar)
        text: root.charging ? "󰂄" : "󰹂"
        color: root.charging ? Color.accent : root.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        anchors.baseline: labelText.baseline
      }

      Item {
        width: Math.max(0, parent.width - labelText.width - valueText.width
          - (hintText.visible ? hintText.width + parent.spacing : 0) - parent.spacing)
        height: 1
      }

      Text {
        id: valueText
        textFormat: Text.PlainText
        text: root.known ? root.level + "%" : "—"
        color: root.low ? Color.urgent : root.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.bodySmall
        font.bold: true
      }
    }

    MeterBar {
      width: parent.width
      value: root.known ? root.level / 100 : -1
      fill: root.low ? Color.urgent : Color.accent
      thickness: Math.max(2, Style.space(3))
    }
  }
}
