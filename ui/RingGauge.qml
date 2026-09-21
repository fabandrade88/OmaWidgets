import QtQuick
import qs.Commons

// The headline reading on a full-size card: a ring with the number inside it.
//
// The same full circle the tiles and the pod gauges draw, so a card and a tile
// showing the same reading look like the same reading. IconRing owns the arc;
// this adds the label that goes in the middle of it.
IconRing {
  id: root

  property string text: ""
  property string caption: ""

  implicitWidth: Style.space(72)
  implicitHeight: implicitWidth
  thickness: Math.max(3, width * 0.085)

  Column {
    anchors.centerIn: parent
    spacing: 0

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      text: root.text
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.heading
      font.bold: true
    }

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      visible: root.caption !== ""
      text: root.caption
      color: Qt.darker(Color.popups.text, 1.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      font.bold: true
    }
  }
}
