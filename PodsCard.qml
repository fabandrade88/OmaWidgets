import QtQuick
import qs.Commons
import "model/Format.js" as Format
import "model/Pods.js" as Pods

// AirPods battery and listening state, read from the librepods daemon's status
// file — the same file the AirPods bar plugin reads.
//
// Display only. The controls live in io.github.thisisgm.omapods, which owns the
// write path to the daemon.
Card {
  id: root

  property var pods: null
  property var config: ({})

  // Guarded accessors, for the moment during a hot-reload when the service is
  // gone but the card has not been torn down yet.
  readonly property var status: pods ? pods.status : Pods.empty()
  readonly property bool hasReading: !!pods && pods.hasBattery
  readonly property bool absent: !pods || pods.absent
  readonly property bool schemaTooNew: !!pods && pods.schemaTooNew
  readonly property int lowestLevel: pods ? pods.lowestLevel : Pods.UNKNOWN
  readonly property bool lowest: lowestLevel >= 0 && lowestLevel <= 20

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

  // Battery keeps arriving over BLE while the audio link is down, so a card with
  // readings is worth drawing even when the pods are not connected.
  Column {
    width: parent.width
    spacing: Style.spacing.md
    visible: root.hasReading

    PodPill {
      visible: !root.status.isHeadset
      width: parent.width
      label: "LEFT"
      pod: root.status.left
    }

    PodPill {
      visible: !root.status.isHeadset
      width: parent.width
      label: "RIGHT"
      pod: root.status.right
    }

    PodPill {
      visible: root.status.isHeadset
      width: parent.width
      label: "HEADPHONES"
      pod: root.status.headset
    }

    PodPill {
      // AirPods Max carry no case, so the row is absent rather than empty.
      visible: !root.status.isHeadset && root.status.caseBattery.available
      width: parent.width
      label: "CASE"
      pod: root.status.caseBattery
      wornHint: false
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
