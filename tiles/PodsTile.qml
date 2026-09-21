import QtQuick
import qs.Commons
import "../ui"
import "../model/Pods.js" as Pods

// The AirPods tile: a two-by-two of rings, each with its mark inside.
//
// Straight from the reference. Four slots for three readings means the grid
// stays square and the empty corner reads as "nothing there" rather than as a
// layout that could not fill itself — the same thing the reference does.
Tile {
  id: root

  property var pods: null
  property var config: ({})

  readonly property var status: pods ? pods.status : Pods.empty()
  readonly property bool hasReading: !!pods && pods.hasBattery
  readonly property int lowestLevel: pods ? pods.lowestLevel : Pods.UNKNOWN
  readonly property bool isHeadset: status.isHeadset

  readonly property real cell: (width - contentLeftInset - contentRightInset
    - Style.spacing.xs) / 2
  readonly property real ringSize: Math.max(Style.space(26), cell * 0.78)

  // The tile's own text layout is replaced by the grid below.
  label: ""
  value: ""
  caption: ""
  fraction: -1
  alert: lowestLevel >= 0 && lowestLevel <= 20

  Grid {
    anchors.centerIn: parent
    visible: root.hasReading
    columns: 2
    spacing: Style.spacing.xs

    PodGauge {
      width: root.cell
      kind: root.isHeadset ? "headset" : "left"
      pod: root.isHeadset ? root.status.headset : root.status.left
      ringSize: root.ringSize
      showLevel: false
    }

    PodGauge {
      width: root.cell
      visible: !root.isHeadset
      kind: "right"
      pod: root.status.right
      ringSize: root.ringSize
      showLevel: false
    }

    PodGauge {
      width: root.cell
      visible: !root.isHeadset
      kind: "case"
      pod: root.status.caseBattery
      ringSize: root.ringSize
      showLevel: false
    }

    // The fourth slot. Drawn as an empty ring so the square stays square, and
    // given a whole cell so the grid's two columns are the same width.
    Item {
      width: root.cell
      height: root.ringSize
      visible: !root.isHeadset

      IconRing {
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.ringSize
        height: root.ringSize
        value: -1
        track: Util.alpha(Color.popups.text, 0.10)
      }
    }
  }

  Text {
    textFormat: Text.PlainText
    anchors.centerIn: parent
    width: parent.width - Style.spacing.lg * 2
    visible: !root.hasReading
    text: root.pods && root.pods.absent ? "No daemon" : "No AirPods"
    horizontalAlignment: Text.AlignHCenter
    color: Qt.darker(Color.popups.text, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
