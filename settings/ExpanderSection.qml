import QtQuick
import qs.Commons

// A settings section that folds away: a title, a one-line summary of what is
// inside, and a chevron that turns when you open it.
//
// The popup is a column in a fixed-width panel, and every section competes for
// the same height. Folding the long ones means the short ones stay visible,
// and the summary means a folded section still says what it is set to.
Column {
  id: root

  property string title: ""
  property string summary: ""
  property bool expanded: false

  default property alias content: holder.children

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  spacing: expanded ? Style.spacing.md : 0

  Item {
    width: parent.width
    height: Math.max(Style.spacing.controlHeight, header.implicitHeight)

    Column {
      id: header
      anchors.left: parent.left
      anchors.right: chevron.left
      anchors.rightMargin: Style.spacing.sm
      anchors.verticalCenter: parent.verticalCenter
      spacing: Style.space(1)

      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: root.title
        color: root.foreground
        font.family: Style.font.family
        font.pixelSize: Style.font.body
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        width: parent.width
        visible: root.summary !== "" && !root.expanded
        text: root.summary
        color: root.dim
        font.family: Style.font.family
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    Text {
      id: chevron
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      textFormat: Text.PlainText
      text: "󰅂"
      color: hover.hovered ? Color.accent : root.dim
      font.family: Style.font.family
      font.pixelSize: Style.font.icon
      rotation: root.expanded ? 90 : 0
      Behavior on rotation { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    HoverHandler { id: hover }

    MouseArea {
      anchors.fill: parent
      cursorShape: Qt.PointingHandCursor
      onClicked: root.expanded = !root.expanded
    }
  }

  // Height is animated rather than the section appearing whole, so the rest of
  // the panel does not jump.
  Item {
    width: parent.width
    height: root.expanded ? holder.implicitHeight : 0
    clip: true
    visible: height > 0

    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

    Column {
      id: holder
      width: parent.width
      spacing: Style.spacing.md
    }
  }
}
