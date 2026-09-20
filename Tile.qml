import QtQuick
import qs.Commons
import qs.Ui

// A compact square.
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
  property bool interactive: false
  property real backgroundOpacity: 0.92

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color accent: alert ? Color.urgent : Color.accent
  readonly property string fontFamily: Style.font.family
  readonly property bool hot: interactive && mouse.containsMouse

  default property alias overlay: overlayHolder.children

  signal activated()

  color: Util.alpha(Color.popups.background, backgroundOpacity)
  borderSpec: Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(1)))
  // A square, so one number sizes it and the grid stays even.
  implicitWidth: height
  opacity: root.hot ? 1 : 0.97

  Behavior on opacity { NumberAnimation { duration: 140 } }

  Item {
    id: content
    anchors.fill: parent
    anchors.margins: root.contentTopInset + Style.spacing.xs

    Row {
      id: header
      anchors.top: parent.top
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: Style.spacing.xs

      Text {
        textFormat: Text.PlainText
        visible: root.glyph !== ""
        text: root.glyph
        color: root.accent
        font.family: root.fontFamily
        font.pixelSize: Style.font.bodySmall
      }

      Text {
        textFormat: Text.PlainText
        text: root.label
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 0.8
        elide: Text.ElideRight
        width: Math.max(0, parent.width - (root.glyph !== "" ? parent.children[0].width + parent.spacing : 0))
      }
    }

    // Bottom-aligned, not centred. A centred number leaves dead space under the
    // header and above the meter, which is what made the first pass read as an
    // empty box with a figure floating in it. Label up top, number down low.
    Column {
      anchors.bottom: meter.top
      anchors.bottomMargin: Style.spacing.sm
      anchors.left: parent.left
      anchors.right: parent.right
      spacing: 0

      Text {
        textFormat: Text.PlainText
        width: parent.width
        text: root.value
        color: root.alert ? Color.urgent : root.foreground
        font.family: root.fontFamily
        // The one number the tile exists to show, so it takes the space.
        font.pixelSize: Style.font.display
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        width: parent.width
        visible: root.caption !== ""
        text: root.caption
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }
    }

    MeterBar {
      id: meter
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      anchors.right: parent.right
      visible: root.fraction >= 0
      value: root.fraction
      fill: root.accent
      thickness: Math.max(2, Style.space(3))
      // A tile with no meter should not reserve the space for one.
      height: visible ? thickness : 0
    }
  }

  Item {
    id: overlayHolder
    anchors.fill: parent
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
