import QtQuick
import Quickshell
import Quickshell.Io

// Runs scripts/omawidgets-fetch and says where the file landed.
//
// Nothing inside the shell process opens a socket: Quickshell's
// XMLHttpRequest cannot bound a response — binary is unreadable until it is
// complete, and text was measured carrying 1.5 MB into its first readable
// moment against a 64 KB cap — so a check in QML always runs after the memory
// has been taken. The helper lets curl stop at the socket instead.
Item {
  id: root

  property int maxBytes: 64 * 1024
  // "any" or "image". An image has to be one by its own magic bytes.
  property string kind: "any"
  property string name: "fetched"

  readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR")
    || ("/run/user/" + Quickshell.env("UID"))
  readonly property string directory: runtimeDir + "/omawidgets"
  readonly property string scriptPath: localPath(Qt.resolvedUrl("../scripts/omawidgets-fetch"))

  readonly property bool busy: process.running

  signal fetched(string path)
  signal failed(int code)

  function localPath(fileUrl) {
    var text = String(fileUrl || "")
    if (text.indexOf("file://") !== 0) return ""
    return decodeURIComponent(text.substring(7))
  }

  // One file per URL, so a cached Image is never a stale cover and two fetches
  // cannot write over each other.
  function pathFor(url) {
    return directory + "/" + name + "-" + Qt.md5(String(url || "")) + ".img"
  }

  function get(url) {
    if (scriptPath === "" || String(url || "") === "") return
    var destination = pathFor(url)
    // A new request replaces one still running: an MPRIS player that changes
    // its artwork in a loop should cost one fetch at a time, not one per
    // change.
    if (process.running) process.running = false
    process.destination = destination
    process.command = [scriptPath, url, destination, String(maxBytes), kind]
    process.running = true
  }

  function cancel() {
    if (process.running) process.running = false
  }

  Process {
    id: process
    property string destination: ""
    onExited: function (code) {
      if (code === 0) root.fetched(destination)
      else root.failed(code)
    }
  }

  Component.onDestruction: cancel()
}
