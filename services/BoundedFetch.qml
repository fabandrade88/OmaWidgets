import QtQuick

// One HTTP GET, with a ceiling on how long it may take and how much of it we
// will ever hold.
//
// Quickshell's XMLHttpRequest has no `timeout` property and no way to cap a
// response, so a stalled server would keep a request open for as long as it
// liked and a large one would be buffered whole before any length check could
// look at it. Three bounds, in the order they can be applied:
//
//   1. A deadline. A timer aborts the request, whatever state it is in.
//   2. The declared length. `Content-Length` is readable at HEADERS_RECEIVED,
//      before a byte of body arrives, and an oversized one is refused there.
//   3. What has actually arrived. Partial bodies are visible at LOADING, so a
//      response that outgrows the cap mid-transfer is aborted then — the
//      connection is torn down instead of the body being collected.
//
// The third is the one that catches a chunked response with no declared length.
Item {
  id: root

  property int maxBytes: 64 * 1024
  property int timeoutMs: 8000
  // "text" or "bytes". Bytes come back as a Uint8Array, for callers that need
  // to look at what arrived rather than read it.
  property string mode: "text"

  readonly property bool active: request !== null

  property var request: null

  signal loaded(string text, var bytes)
  signal failed(string reason)

  function get(url) {
    cancel()
    if (String(url || "") === "") return
    var xhr = new XMLHttpRequest()
    request = xhr
    if (root.mode === "bytes") xhr.responseType = "arraybuffer"
    xhr.onreadystatechange = function () { root.advance(xhr) }
    deadline.restart()
    xhr.open("GET", url)
    xhr.send()
  }

  function cancel() {
    deadline.stop()
    var pending = request
    request = null
    if (pending) pending.abort()
  }

  // Deferred, because aborting from inside the request's own state-change
  // callback wedged the engine when the server was mid-body: the abort is
  // queued and the handler returns first.
  function stop(reason) {
    if (!request) return
    var pending = request
    request = null
    deadline.stop()
    Qt.callLater(function () { pending.abort() })
    root.failed(reason)
  }

  function advance(xhr) {
    if (request !== xhr) return
    if (xhr.readyState === XMLHttpRequest.HEADERS_RECEIVED) {
      var declared = Number(xhr.getResponseHeader("content-length"))
      if (isFinite(declared) && declared > root.maxBytes) stop("too large")
      return
    }
    if (xhr.readyState === XMLHttpRequest.LOADING) {
      if (root.mode === "text" && (xhr.responseText || "").length > root.maxBytes) stop("too large")
      return
    }
    if (xhr.readyState !== XMLHttpRequest.DONE) return

    deadline.stop()
    request = null
    if (xhr.status !== 200) {
      root.failed(xhr.status === 0 ? "no answer" : "http " + xhr.status)
      return
    }
    if (root.mode === "bytes") {
      var buffer = xhr.response
      var size = buffer ? buffer.byteLength : 0
      if (size === 0 || size > root.maxBytes) {
        root.failed(size === 0 ? "empty" : "too large")
        return
      }
      root.loaded("", new Uint8Array(buffer))
      return
    }
    var body = xhr.responseText || ""
    if (body.length > root.maxBytes) {
      root.failed("too large")
      return
    }
    root.loaded(body, null)
  }

  Timer {
    id: deadline
    interval: root.timeoutMs
    onTriggered: root.stop("timed out")
  }

  Component.onDestruction: cancel()
}
