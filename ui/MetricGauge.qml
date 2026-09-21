import QtQuick
import qs.Commons

// One reading inside a tile: a ring with its mark, the value underneath.
// The unit the wide Performance tile is built from.
Item {
  id: root

  property string glyph: ""
  property string value: ""
  property string caption: ""
  property real fraction: -1
  property bool alert: false
  property real ringSize: Style.space(46)

  readonly property color accent: alert ? Color.urgent : Color.accent

  implicitWidth: ringSize
  implicitHeight: column.implicitHeight

  Column {
    id: column
    width: parent.width
    spacing: Style.spacing.xs

    IconRing {
      anchors.horizontalCenter: parent.horizontalCenter
      width: root.ringSize
      height: root.ringSize
      value: root.fraction
      fill: root.accent

      Text {
        anchors.centerIn: parent
        textFormat: Text.PlainText
        text: root.glyph
        color: Color.popups.text
        font.family: Style.font.family
        font.pixelSize: parent.height * 0.5
      }
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.value
      color: root.alert ? Color.urgent : Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.subtitle
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: root.caption !== ""
      text: root.caption
      color: Qt.darker(Color.popups.text, 1.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }
}
