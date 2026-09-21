import QtQuick
import Quickshell
import "../model/Pods.js" as Pods
import "../model/PodsView.js" as PodsView

// AirPods readings, taken from the status file the librepods daemon publishes.
//
// Read-only by design. Listening mode, ear detection and the other controls
// belong to io.github.thisisgm.omapods, which owns the write path to the daemon;
// two panels racing optimistic writes for one device would be worse than one
// panel that only reports.
//
// There is no timer here at all. The daemon rewrites the file on change and
// FileView watches it, so an idle pair of AirPods costs exactly nothing.
Item {
  id: root

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")
  readonly property string statePath: stateHome + "/librepods/status.json"

  property var status: Pods.empty()

  readonly property bool daemonRunning: status.daemonRunning
  readonly property bool connected: status.connected
  readonly property bool hasBattery: PodsView.hasAnyBattery(status)
  readonly property bool schemaTooNew: status.schemaTooNew
  readonly property string error: stateFile.oversized
    ? "The librepods status file is too large to read" : status.error
  readonly property bool oversized: stateFile.oversized
  // The daemon is absent, not just quiet — the plugin is probably not installed.
  readonly property bool absent: !status.daemonRunning

  readonly property int lowestLevel: PodsView.lowestPodLevel(status)
  readonly property string noiseModeName: PodsView.noiseModeName(status.noiseMode)
  readonly property string lidName: PodsView.lidName(status.lidState)

  // Falls back to the family name, then to a generic label, so the card always
  // has a title even for a device the daemon has not fully identified.
  readonly property string title: status.deviceName || status.modelName || "AirPods"

  function refresh() {
    stateFile.reload()
  }

  GuardedFile {
    id: stateFile
    path: root.statePath
    maxBytes: Pods.MAX_FILE
    onTextLoaded: function (body) { root.status = Pods.parse(body) }
    // The daemon removes the file when it stops, so an absent file means a
    // stopped daemon rather than an error worth showing.
    onMissing: root.status = Pods.empty()
  }
}
