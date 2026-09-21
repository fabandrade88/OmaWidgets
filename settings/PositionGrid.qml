import QtQuick
import qs.Commons
import qs.Ui
import "../model/Settings.js" as Settings

// Where the desktop cards sit, as a miniature of the screen.
//
// A 3x3 of cells reads faster than a dropdown of eight names, and the centre cell
// is deliberately inert: cards in the middle of the screen would sit under
// whatever window is focused, which is not a placement worth offering.
Item {
  id: root

  property string position: Settings.DEFAULTS.position

  signal picked(string position)

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)
  readonly property real cellSize: Style.space(26)

  // Row-major, with the inert centre as an empty string.
  readonly property var cells: [
    "top-left", "top-center", "top-right",
    "middle-left", "", "middle-right",
    "bottom-left", "bottom-center", "bottom-right"
  ]

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  Grid {
    id: grid
    columns: 3
    spacing: Style.spacing.xs

    Repeater {
      model: root.cells

      BorderSurface {
        id: cell

        readonly property bool selectable: modelData !== ""
        readonly property bool isActive: selectable && modelData === root.position
        readonly property bool hot: selectable && mouse.containsMouse

        width: root.cellSize
        height: root.cellSize * 0.72
        radius: Style.cornerRadius
        color: isActive ? Style.selectedAccentFill : (hot ? Style.hoverFill : Style.normalFill)
        opacity: selectable ? 1 : 0.25
        borderSpec: Border.controlSpec(isActive ? "selected" : (hot ? "hover" : "normal"),
          root.foreground, Color.accent, Color.urgent)

        // A filled pip in the corner the cards would occupy, so the cell shows
        // the placement rather than naming it.
        Rectangle {
          visible: cell.selectable
          width: parent.width * 0.4
          height: parent.height * 0.42
          radius: Style.cornerRadius > 0 ? Math.min(width, height) / 3 : 0
          color: cell.isActive ? Color.accent : root.dim
          anchors.margins: Style.space(3)
          anchors.top: String(modelData).indexOf("top") === 0 ? parent.top : undefined
          anchors.bottom: String(modelData).indexOf("bottom") === 0 ? parent.bottom : undefined
          anchors.verticalCenter: String(modelData).indexOf("middle") === 0
            ? parent.verticalCenter : undefined
          anchors.left: String(modelData).indexOf("-left") > 0 ? parent.left : undefined
          anchors.right: String(modelData).indexOf("-right") > 0 ? parent.right : undefined
          anchors.horizontalCenter: String(modelData).indexOf("-center") > 0
            ? parent.horizontalCenter : undefined
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: cell.selectable
          enabled: cell.selectable
          cursorShape: Qt.PointingHandCursor
          onClicked: root.picked(modelData)
        }
      }
    }
  }
}
