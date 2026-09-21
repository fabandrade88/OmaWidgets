import QtQuick
import qs.Commons
import qs.Ui

// Chrome shared by every widget card.
//
// Colour, radius, border, type scale and spacing all come from the active
// Omarchy theme's own singletons — the same ones the stock panels read — so a
// theme switch restyles these cards in the same frame as the rest of the shell,
// with nothing to configure and no palette of our own to drift out of step.
BorderSurface {
  id: root

  property string title: ""
  property string glyph: ""
  property string meta: ""
  property bool compact: false
  property bool alert: false
  property bool selected: false
  property bool closable: false
  property bool hovered: false

  signal closeRequested()
  property real backgroundOpacity: 0.92

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property color accent: alert ? Color.urgent : Color.accent
  readonly property string fontFamily: Style.font.family

  default property alias content: contentColumn.children

  color: Util.alpha(Color.popups.background, backgroundOpacity)
  radius: Style.cornerRadius
  // Selection is drawn as a flat accent border rather than the theme's own
  // selected-control tokens: some themes give those zero width, and a selection
  // you cannot see is worse than one that does not match the palette exactly.
  borderSpec: selected
    ? Border.flat(Color.accent, Math.max(2, Style.space(2)))
    : Border.surfaceSpec("popups", "border", Color.popups.border, Math.max(1, Style.space(1)))
  padding: compact ? Style.spacing.popupPadding : Style.spacing.panelPadding

  implicitHeight: contentTopInset + header.implicitHeight + gap + contentColumn.implicitHeight
    + contentBottomInset

  readonly property real gap: contentColumn.children.length > 0
    ? (compact ? Style.spacing.md : Style.spacing.lg) : 0

  Row {
    id: header
    anchors.top: parent.top
    anchors.topMargin: root.contentTopInset
    anchors.left: parent.left
    anchors.leftMargin: root.contentLeftInset
    anchors.right: parent.right
    anchors.rightMargin: root.contentRightInset
    spacing: Style.spacing.md

    Text {
      id: glyphText
      textFormat: Text.PlainText
      visible: root.glyph !== ""
      text: root.glyph
      color: root.accent
      font.family: root.fontFamily
      font.pixelSize: Style.font.icon
      anchors.verticalCenter: titleColumn.verticalCenter
    }

    Column {
      id: titleColumn
      width: parent.width - (glyphText.visible ? glyphText.width + parent.spacing : 0)
      spacing: Style.space(1)

      Text {
        textFormat: Text.PlainText
        width: parent.width
        // Device and model names arrive over Bluetooth and CPU strings come from
        // /proc, so every title is foreign text: PlainText and elided, never
        // interpreted and never allowed to stretch the card.
        text: root.title
        color: root.foreground
        font.family: root.fontFamily
        font.pixelSize: Style.font.subtitle
        font.bold: true
        elide: Text.ElideRight
      }

      Text {
        textFormat: Text.PlainText
        width: parent.width
        visible: root.meta !== ""
        text: root.meta.toUpperCase()
        color: root.dim
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.1
        elide: Text.ElideRight
      }
    }
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

  Column {
    id: contentColumn
    anchors.top: header.bottom
    anchors.topMargin: root.gap
    anchors.left: parent.left
    anchors.leftMargin: root.contentLeftInset
    anchors.right: parent.right
    anchors.rightMargin: root.contentRightInset
    spacing: root.compact ? Style.spacing.sm : Style.spacing.md
  }
}
