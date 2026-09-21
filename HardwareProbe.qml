import QtQuick
import Quickshell.Io
import "model/Probe.js" as Probe

// Runs scripts/omawidgets-probe once and holds what it found.
//
// This is the plugin's only process spawn on the read path, and it happens once
// per shell session. Everything the probe discovers is a file path, which the
// services then read with FileView — so sampling itself costs no fork, no exec
// and no shell.
Item {
  id: root

  readonly property string scriptPath: localPath(Qt.resolvedUrl("scripts/omawidgets-probe"))

  property var values: ({})
  property bool ready: false
  property string error: ""

  signal refreshed()

  // The script lives next to this file, so its path comes from Qt's own URL
  // resolution rather than from settings or the environment. There is no code
  // path by which a user-supplied string becomes the command being run.
  function localPath(url) {
    var text = String(url || "")
    if (text.indexOf("file://") !== 0) return ""
    return decodeURIComponent(text.substring(7))
  }

  function refresh() {
    if (probeProcess.running || scriptPath === "") return
    probeProcess.running = true
  }

  function apply(raw) {
    values = Probe.parse(raw)
    ready = true
    error = ""
    refreshed()
  }

  function text(key, fallback) { return Probe.text(values, key, fallback) }
  function path(key) { return Probe.path(values, key) }
  function program(key) { return Probe.program(values, key) }
  function number(key, fallback) { return Probe.number(values, key, fallback) }
  function flag(key) { return Probe.flag(values, key) }

  Process {
    id: probeProcess
    // Invoked through bash rather than relying on the file mode, so a checkout
    // that lost its exec bit still works. The argv is constant except for a path
    // derived from this file's own location.
    command: ["bash", "--", root.scriptPath]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.apply(text)
    }
    stderr: StdioCollector { id: probeError; waitForEnd: true }
    onExited: function (exitCode) {
      if (exitCode === 0) return
      root.ready = true
      root.error = String(probeError.text || "hardware probe failed").slice(0, 200)
    }
  }

  Component.onCompleted: refresh()
}
