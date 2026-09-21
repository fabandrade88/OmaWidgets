import QtQuick
import qs.Commons

// A left pod, a right pod, or the case — drawn rather than set in a font.
//
// No Nerd Font glyph is an AirPod. The nearest candidates are a headphone can or
// a gear, which say "audio" but not "this bud, that bud, the case" — and telling
// the three apart at a glance is the whole point of the reference design. A few
// rounded rectangles cost less than a font dependency and mirror cleanly, so the
// left and right marks are genuinely mirrored rather than one picture twice.
Item {
  id: root

  // "left", "right", "case", or "headset"
  property string kind: "left"
  property color color: Color.popups.text
  // The colour showing through the case's lid seam. Matching the surface behind
  // the mark is what makes a filled shape read as an outline.
  property color cutout: Color.popups.background
  property real size: Style.space(20)

  readonly property bool isCase: kind === "case"
  readonly property bool isHeadset: kind === "headset"
  readonly property real unit: size

  implicitWidth: size
  implicitHeight: size

  Item {
    id: bud
    visible: !root.isCase && !root.isHeadset
    anchors.fill: parent
    // Mirrored, so the pair reads as a pair instead of one shape repeated.
    transform: Scale {
      origin.x: bud.width / 2
      xScale: root.kind === "right" ? -1 : 1
    }

    // The driver housing: a little wider than tall, like the real one.
    Rectangle {
      width: root.unit * 0.56
      height: root.unit * 0.48
      radius: height / 2
      color: root.color
      x: root.unit * 0.20
      y: root.unit * 0.10
    }

    // The stem, hanging from the front of the housing rather than its centre,
    // which is the notch that makes the silhouette read as an earbud.
    Rectangle {
      width: root.unit * 0.17
      height: root.unit * 0.44
      radius: width / 2
      color: root.color
      x: root.unit * 0.27
      y: root.unit * 0.46
      transform: Rotation { origin.x: root.unit * 0.085; origin.y: 0; angle: 10 }
    }
  }

  // AirPods Max are a headset, not a pair of buds. This is the one mark taken
  // from the font rather than drawn: the headphone glyph is unambiguous, and a
  // device with a single battery does not need a left and a right that mirror.
  Text {
    visible: root.isHeadset
    anchors.centerIn: parent
    textFormat: Text.PlainText
    text: "󰋋"
    color: root.color
    font.family: Style.font.family
    font.pixelSize: root.unit * 0.86
  }

  // The case: a filled rounded rectangle with the lid seam cut out of it.
  Item {
    visible: root.isCase
    anchors.centerIn: parent
    width: root.unit * 0.88
    height: root.unit * 0.68

    Rectangle {
      anchors.fill: parent
      radius: height * 0.32
      color: root.color
    }

    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      y: parent.height * 0.34
      width: parent.width * 0.54
      height: Math.max(1.5, root.unit * 0.08)
      radius: height / 2
      color: root.cutout
    }
  }
}
