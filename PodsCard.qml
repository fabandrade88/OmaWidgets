import QtQuick
import qs.Commons
import "model/Format.js" as Format
import "model/Pods.js" as Pods

// AirPods battery and listening state, read from the librepods daemon's status
// file — the same file the AirPods bar plugin reads.
//
// Laid out the way Apple's own battery widget is: a ring per part with its mark
// inside and the level underneath, so the pair and the case are read side by
// side rather than as three stacked bars.
//
// Display only. The controls live in io.github.thisisgm.omapods, which owns the
// write path to the daemon.
Card {
  id: root

  property var pods: null
  property var config: ({})

  readonly property var status: pods ? pods.status : Pods.empty()
  readonly property bool hasReading: !!pods && pods.hasBattery
  readonly property bool absent: !pods || pods.absent
  readonly property bool schemaTooNew: !!pods && pods.schemaTooNew
  readonly property int lowestLevel: pods ? pods.lowestLevel : Pods.UNKNOWN
  readonly property bool lowest: lowestLevel >= 0 && lowestLevel <= 20

  // AirPods Max carry no case and no second bud, so their card is one gauge.
  readonly property bool isHeadset: status.isHeadset

  title: pods ? pods.title : "AirPods"
  glyph: "󰋋"
  alert: lowest
  meta: Format.joinMeta([
    status.connected
      ? (Pods.noiseModeName(status.noiseMode) !== ""
        ? Pods.noiseModeName(status.noiseMode) : "Connected")
      : "Not connected",
    Pods.lidName(status.lidState)
  ])

  Row {
    width: parent.width
    visible: root.hasReading
    spacing: 0

    // Evenly spread, so two gauges and three both sit balanced under the title.
    property int slots: root.isHeadset ? 1 : (root.status.caseBattery.available ? 3 : 2)

    PodGauge {
      visible: root.isHeadset
      width: parent.width / parent.slots
      kind: "headset"
      pod: root.status.headset
      ringSize: root.compact ? Style.space(42) : Style.space(54)
    }

    PodGauge {
      visible: !root.isHeadset
      width: parent.width / parent.slots
      kind: "left"
      pod: root.status.left
      ringSize: root.compact ? Style.space(42) : Style.space(54)
    }

    PodGauge {
      visible: !root.isHeadset
      width: parent.width / parent.slots
      kind: "right"
      pod: root.status.right
      ringSize: root.compact ? Style.space(42) : Style.space(54)
    }

    PodGauge {
      visible: !root.isHeadset && root.status.caseBattery.available
      width: parent.width / parent.slots
      kind: "case"
      pod: root.status.caseBattery
      ringSize: root.compact ? Style.space(42) : Style.space(54)
    }
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: !root.hasReading
    // Three different situations, three different things to do about them.
    text: {
      if (root.absent)
        return "No librepods daemon. Install the AirPods plugin to publish battery state."
      if (root.schemaTooNew)
        return "The librepods daemon speaks a newer status format than this card reads."
      return "Waiting for the daemon to report a device."
    }
    color: Qt.darker(root.foreground, 1.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: root.hasReading && root.status.noiseMode === Pods.NOISE_ADAPTIVE
      && Format.isKnown(root.status.adaptiveLevel)
    text: "Adaptive noise at " + root.status.adaptiveLevel + "%"
    color: Qt.darker(root.foreground, 1.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
  }
}
