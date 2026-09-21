import QtQuick
import qs.Commons

// One pod, or the case: a ring with its mark inside and the level underneath.
// The unit the AirPods card and the AirPods tile are both built from.
Item {
  id: root

  property string kind: "left"
  property var pod: null
  property real ringSize: Style.space(46)
  property bool showLevel: true

  readonly property int level: pod ? pod.level : -1
  readonly property bool known: level >= 0
  readonly property bool charging: !!pod && pod.charging === true
  readonly property bool inEar: !!pod && pod.inEar === true
  readonly property bool low: known && level <= 20 && !charging

  readonly property color accent: low ? Color.urgent : Color.accent
  // An absent pod keeps its place in the row, drawn as an empty ring, so the
  // layout does not reshuffle when one is taken out of the case.
  readonly property color markColor: known
    ? Color.popups.text : Util.alpha(Color.popups.text, 0.35)

  implicitWidth: Math.max(ringSize, levelText.implicitWidth)
  implicitHeight: ringSize + (showLevel ? levelText.implicitHeight + Style.spacing.xs : 0)

  IconRing {
    id: ring
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.ringSize
    height: root.ringSize
    value: root.known ? root.level / 100 : -1
    fill: root.accent
    charging: root.charging

    PodMark {
      anchors.centerIn: parent
      kind: root.kind
      color: root.markColor
      cutout: Color.popups.background
      size: parent.width
    }
  }

  Text {
    id: levelText
    textFormat: Text.PlainText
    visible: root.showLevel
    anchors.top: ring.bottom
    anchors.topMargin: Style.spacing.xs
    anchors.horizontalCenter: parent.horizontalCenter
    text: root.known ? root.level + "%" : "—"
    color: root.low ? Color.urgent : Color.popups.text
    font.family: Style.font.family
    font.pixelSize: Style.font.subtitle
    font.bold: true
  }
}
