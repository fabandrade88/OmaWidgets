import QtQuick
import qs.Commons
import qs.Ui

// Where the widgets sit and how big they are, split out of the popup so each
// section of it reads as a section.
Column {
  id: root

  required property var config

  signal positionPicked(string position)
  signal columnsChanged(int columns)
  signal tileSizeChanged(int size)

  readonly property color foreground: Color.popups.text

  spacing: Style.spacing.md

  PanelSectionHeader {
    width: parent.width
    text: "Position"
    foreground: root.foreground
  }

  PositionGrid {
    anchors.horizontalCenter: parent.horizontalCenter
    position: root.config.position
    onPicked: function (value) { root.positionPicked(value) }
  }

  PanelSeparator { width: parent.width }

  // A dropdown rather than a row of switches: five widgets is already most of
  // the popup's height, and the list only grows.
  MultiSelect {
    width: parent.width
    label: "Cards"
    foreground: root.foreground
    noSelectionText: "None"
    options: root.cardOptions
    values: root.config.cards
    onChanged: function (values) { root.cardsPicked(values) }
  }
}
