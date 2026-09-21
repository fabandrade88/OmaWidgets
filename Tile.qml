import QtQuick
import qs.Commons
import qs.Ui

// A compact square: a ring with the mark inside it, and the reading underneath.
//
// Its corners are rounded from `radius` rather than from Style.cornerRadius: a
// theme with square corners still wants its small tiles rounded, and that
// softness is the whole visual idea of compact mode. Every colour still comes
// from the theme.
BorderSurface {
  id: root

  property string glyph: ""
  property string label: ""
  property string value: ""
  property string caption: ""
  property real fraction: -1
  property bool alert: false
  property bool selected: false
  property bool closable: false
  property bool hovered: false

  signal closeRequested()
  property bool interactive: false
  property real backgroundOpacity: 0.92

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color accent: alert ? Color.urgent : Color.accent
  readonly property string fontFamily: Style.font.family
  readonly property bool hot: interactive && mouse.containsMouse

  // A word rather than a percentage — "Balanced" — needs a size that fits.
  readonly property int valueSize: value.length > 5 ? Style.font.title : Style.font.display

  default property alias overlay: overlayHolder.children

  // Drawn where the ring goes, for a tile whose reading is a picture rather
  // than a number — the album cover.
  property Component artwork: null

  signal activated()

  color: Util.alpha(Color.popups.background, backgroundOpacity)
  // Selection is drawn as a flat accent border rather than the theme's own
  // selected-control tokens: some themes give those zero width, and a selection
  // you cannot see is worse than one that does not match the palette exactly.
  borderSpec: selected
    ? Border.flat(Color.accent, Math.max(2, Style.space(2)))
    : Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(1)))
  // A square, so one number sizes it and the grid stays even.
  implicitWidth: height
  opacity: root.hot ? 1 : 0.97

  Behavior on opacity { NumberAnimation { duration: 140 } }

  Column {
    id: content
    anchors.centerIn: parent
    width: parent.width - root.contentLeftInset - root.contentRightInset
    spacing: Style.spacing.xs
    visible: root.glyph !== "" || root.value !== ""

    Item {
      id: mark
      anchors.horizontalCenter: parent.horizontalCenter
      // Leaves room for the reading underneath without crowding it.
      width: Math.min(parent.width * 0.62, root.height * 0.46)
      height: width
      visible: root.artwork !== null || root.glyph !== "" || root.fraction >= 0

      IconRing {
        anchors.fill: parent
        visible: root.artwork === null
        value: root.fraction
        fill: root.accent

        Text {
          anchors.centerIn: parent
          textFormat: Text.PlainText
          text: root.glyph
          color: root.foreground
          font.family: root.fontFamily
          font.pixelSize: parent.height * 0.52
        }
      }

      Loader {
        anchors.fill: parent
        active: root.artwork !== null
        sourceComponent: root.artwork
      }
    }

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      text: root.value
      color: root.alert ? Color.urgent : root.foreground
      font.family: root.fontFamily
      font.pixelSize: root.valueSize
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      anchors.horizontalCenter: parent.horizontalCenter
      width: parent.width
      horizontalAlignment: Text.AlignHCenter
      visible: root.caption !== ""
      text: root.caption
      color: root.dim
      font.family: root.fontFamily
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  Item {
    id: overlayHolder
    anchors.fill: parent
  }

  // Hover is tracked with a handler rather than a MouseArea so it never takes
  // the press away from anything inside the widget.
  HoverHandler {
    id: hover
    enabled: root.closable
    onHoveredChanged: root.hovered = hovered
  }

  CloseButton {
    anchors.top: parent.top
    anchors.right: parent.right
    anchors.margins: Style.spacing.xs
    z: 20
    shown: root.closable && root.hovered
    onActivated: root.closeRequested()
  }

  MouseArea {
    id: mouse
    anchors.fill: parent
    enabled: root.interactive
    hoverEnabled: root.interactive
    cursorShape: Qt.PointingHandCursor
    onClicked: root.activated()
  }
}
