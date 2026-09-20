import QtQuick
import QtQuick.Shapes
import qs.Commons

// The card's headline reading, drawn as an arc with the number inside it.
//
// Shape with the curve renderer keeps this on the GPU and antialiased at any
// scale, and the two ShapePaths are rebuilt only when `value` changes rather
// than on every frame.
Item {
  id: root

  property real value: -1
  property string text: ""
  property string caption: ""
  property color fill: Color.accent
  property real thickness: Math.max(3, Style.space(5))

  readonly property color track: Util.alpha(Color.popups.text, 0.14)
  readonly property bool known: value >= 0
  readonly property real clamped: Util.clampAlpha(value)
  readonly property real radius: (Math.min(width, height) - thickness) / 2

  // Leaves a gap at the bottom so the arc reads as a gauge rather than a pie.
  readonly property real startAngle: 135
  readonly property real sweep: 270

  implicitWidth: Style.space(72)
  implicitHeight: Style.space(72)

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    asynchronous: false

    ShapePath {
      strokeColor: root.track
      strokeWidth: root.thickness
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap

      PathAngleArc {
        centerX: root.width / 2
        centerY: root.height / 2
        radiusX: root.radius
        radiusY: root.radius
        startAngle: root.startAngle
        sweepAngle: root.sweep
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
        startAngle: root.startAngle
        // A zero-length arc with a round cap still paints a dot, which would read
        // as a reading where there is none.
        sweepAngle: root.known ? root.sweep * root.clamped : 0

        Behavior on sweepAngle {
          NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
        }
      }
    }
  }

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
