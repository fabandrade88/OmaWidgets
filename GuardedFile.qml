import QtQuick
import Quickshell.Io

// A watched file with a size it refuses to keep re-reading.
//
// Quickshell's FileView has no way to bound a read: by the time the contents can
// be measured they have already been loaded, and a twenty-megabyte file inflates
// the shell's heap by an order of magnitude that it does not give back. The
// parsers cap what they will accept, but that is after the cost has been paid.
//
// So the size is checked on arrival, and a file that comes back too big stops
// being re-read on every change — it is re-checked on a slow timer instead. The
// first read still costs; a daemon rewriting a huge file twice a second no
// longer costs anything more. A file that shrinks back recovers on its own.
Item {
  id: root

  property string path: ""
  property int maxBytes: 256 * 1024
  // How long to wait before looking again at a file that was too large.
  property int recheckMs: 60000

  readonly property bool oversized: _oversized
  readonly property bool ready: _ready

  signal textLoaded(string body)
  signal missing()

  property bool _oversized: false
  property bool _ready: false

  function reload() {
    view.reload()
  }

  // Measured as bytes, before anything asks for it as text. text() converts the
  // whole file to UTF-16 and hands it across a signal as a string, and each of
  // those is a copy; byteLength is a number on a buffer that already exists.
  function _accept() {
    _ready = true
    var bytes = view.data()
    if (!bytes || bytes.byteLength > maxBytes) {
      _oversized = !!bytes
      if (_oversized) recheck.restart()
      return
    }
    _oversized = false
    recheck.stop()
    textLoaded(view.text())
  }

  FileView {
    id: view
    path: root.path
    watchChanges: true
    printErrors: false
    // A file already known to be too large is not re-read on every write; the
    // timer below decides when to look again.
    onFileChanged: if (!root._oversized) reload()
    onLoaded: root._accept()
    onLoadFailed: {
      root._ready = true
      root._oversized = false
      root.missing()
    }
  }

  Timer {
    id: recheck
    interval: root.recheckMs
    repeat: false
    onTriggered: view.reload()
  }
}
