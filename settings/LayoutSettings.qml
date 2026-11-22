import QtQuick
import qs.Commons

// Where the widgets sit and how big they are.
Column {
  id: root

  required property var config

  signal positionPicked(string position)
  signal settingChanged(string key, int value)

  readonly property color foreground: Color.popups.text

  spacing: Style.spacing.md

  PositionGrid {
    anchors.horizontalCenter: parent.horizontalCenter
    position: root.config.position
    onPicked: function (value) { root.positionPicked(value) }
  }

  StepperRow {
    width: parent.width
    label: "Columns"
    // The tile grid places cards by cell, so columns are not its business.
    visible: !root.config.grid || root.config.compact
    description: root.config.compact
      ? "Tiles across before wrapping to the next row."
      : "Cards across before wrapping to the next row."
    value: root.config.columns
    minimum: 1
    maximum: 6
    onChanged: function (value) { root.settingChanged("columns", value) }
  }

  StepperRow {
    width: parent.width
    visible: root.config.compact
    label: "Tile size"
    description: "Tiles are square, so one number sizes them."
    value: root.config.tileSize
    minimum: 88
    maximum: 260
    step: 4
    suffix: "px"
    onChanged: function (value) { root.settingChanged("tileSize", value) }
  }
}
