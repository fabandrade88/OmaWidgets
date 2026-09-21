import QtQuick
import QtQuick.Shapes
import qs.Commons

// A full-circle progress ring with a mark in the middle, the way iOS and macOS
// draw a battery widget.
//
// A complete circle rather than the 270° gauge used on the big cards: at this
// size the gap reads as damage, and a ring that closes is easier to compare
// against the one beside it.
Item {
  id: root

  property real value: -1
  property color fill: Color.accent
  property color track: Util.alpha(Color.popups.text, 0.16)
  property real thickness: Math.max(2.5, width * 0.09)
  property bool charging: false

  default property alias content: holder.children

  readonly property bool known: value >= 0
  readonly property real clamped: Util.clampAlpha(value)
  readonly property real radius: (Math.min(width, height) - thickness) / 2

  implicitWidth: Style.space(44)
  implicitHeight: implicitWidth

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    asynchronous: false

    ShapePath {
      strokeColor: root.track
      strokeWidth: root.thickness
      fillColor: "transparent"
      PathAngleArc {
        centerX: root.width / 2
        centerY: root.height / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: 0
        sweepAngle: 360
      }
    }

    ShapePath {
      strokeColor: root.fill
      strokeWidth: root.thickness
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.width / 2
        centerY: root.height / 2
        radiusX: root.radius
        radiusY: root.radius
        // Twelve o'clock, clockwise, like every battery ring people already read.
        startAngle: -90
        // A round cap on a zero-length arc still paints a dot, which would read
        // as a reading where there is none.
        sweepAngle: root.known ? 360 * root.clamped : 0

        // Deliberately not animated. Easing the sweep re-tessellates the arc on
        // every frame of every transition, and with six rings on screen that
        // measured at 2.6 points of a core — more than a third of the plugin's
        // whole cost — to soften a change that happens every two seconds and
        // reads perfectly well as a step. The curve renderer stays: the geometry
        // one is visibly jagged at these sizes and saves far less.

      }
    }
  }

  Item {
    id: holder
    anchors.centerIn: parent
    width: parent.width * 0.62
    height: parent.height * 0.62
  }

  // Charging sits on the ring at twelve o'clock, breaking the stroke, exactly
  // where the reference puts it.
  Item {
    visible: root.charging
    width: root.thickness * 3.4
    height: width
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: -height * 0.18

    Rectangle {
      anchors.fill: parent
      radius: width / 2
      color: Color.popups.background
    }

    Text {
      anchors.centerIn: parent
      textFormat: Text.PlainText
      text: "󰉁"
      color: root.fill
      font.family: Style.font.family
      font.pixelSize: parent.height * 0.82
    }
  }
}
