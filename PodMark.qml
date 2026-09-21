import QtQuick
import QtQuick.Shapes
import qs.Commons

// A left pod, a right pod, the case, or a headset — drawn here rather than
// taken from a font or from a vendor's artwork.
//
// No Nerd Font glyph is an AirPod; the nearest candidates say "audio" without
// saying which bud, which is the one thing these marks exist to say. The
// omarchy-pods plugin solves it with Apple's own product outlines lifted from
// apple.com, which is a fine choice for a plugin but not one worth copying into
// a separately published one. These are original silhouettes in a 100×100 box:
// one path each, so the shapes union cleanly instead of showing seams where
// overlapping rectangles meet.
Item {
  id: root

  // "left", "right", "case", or "headset"
  property string kind: "left"
  property color color: Color.popups.text
  // What shows through the case's lid seam. Matching the surface behind the
  // mark is what makes a filled shape read as an outline.
  property color cutout: Color.popups.background
  property real size: Style.space(20)

  readonly property bool isCase: kind === "case"
  readonly property bool isHeadset: kind === "headset"
  readonly property bool isRight: kind === "right"

  implicitWidth: size
  implicitHeight: size

  // An AirPods bud seen from the front: the driver housing, the ear tip off its
  // inner edge, and a stem clearly narrower than the head. That waist between
  // head and stem is what makes the silhouette read as an earbud rather than a
  // blob once it is under thirty pixels.
  readonly property string budPath:
      "M 25 33 A 26 26 0 1 1 77 33 A 26 26 0 1 1 25 33 Z"
    + " M 19 36 A 10 10 0 1 1 39 36 A 10 10 0 1 1 19 36 Z"
    + " M 42 46 L 60 46 L 60 85 A 9 9 0 0 1 42 85 Z"

  // The case: a rounded body, wider than tall, like the real one.
  readonly property string casePath:
      "M 22 27 L 78 27 C 87 27 93 34 93 43 L 93 69"
    + " C 93 78 87 85 78 85 L 22 85 C 13 85 7 78 7 69"
    + " L 7 43 C 7 34 13 27 22 27 Z"

  Shape {
    visible: !root.isHeadset
    // Fixed at the path's own coordinate space and scaled from its corner, not
    // anchored to the item and scaled about its middle — that put the shape
    // outside its own box at any size but 100 and clipped it to a fragment.
    width: 100
    height: 100
    preferredRendererType: Shape.CurveRenderer
    // The stem goes under a pixel wide at tile size; sampling above the painted
    // size keeps it a stem rather than a dashed line.
    layer.enabled: true
    layer.smooth: true
    layer.textureSize: Qt.size(Math.max(32, root.size * 3), Math.max(32, root.size * 3))

    transform: [
      Scale {
        origin.x: 0
        origin.y: 0
        // Mirrored, so the pair reads as a pair rather than one shape twice.
        xScale: (root.isRight ? -1 : 1) * root.size / 100
        yScale: root.size / 100
      },
      // A negative scale about the corner puts the shape at negative x; this
      // brings it back into the box.
      Translate { x: root.isRight ? root.size : 0; y: 0 }
    ]

    ShapePath {
      fillColor: root.color
      // Negative, not zero: zero still strokes, and strokeColor defaults white.
      strokeWidth: -1
      fillRule: ShapePath.WindingFill
      PathSvg { path: root.isCase ? root.casePath : root.budPath }
    }
  }

  // The lid seam, drawn in the colour behind the mark so the case reads as a
  // case rather than as a plain rounded rectangle.
  Rectangle {
    visible: root.isCase
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.size * 0.52
    width: root.size * 0.52
    height: Math.max(1.5, root.size * 0.07)
    radius: height / 2
    color: root.cutout
  }

  // AirPods Max are a headset, not a pair of buds. The one mark taken from the
  // font: a device with a single battery needs no left and right to mirror.
  Text {
    visible: root.isHeadset
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: "󰋋"
    color: root.color
    font.family: Style.font.family
    font.pixelSize: root.size * 0.86
  }
}
