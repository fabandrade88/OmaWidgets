import QtQuick
import "../services"
import "../model/Bytes.js" as Bytes
import "../model/Media.js" as Media

// Album art: local files read directly, remote ones fetched with a ceiling.
//
// The URL comes from whatever application registered itself on MPRIS — any
// process on the session bus can publish one — and an Image handed a remote URL
// downloads whatever arrives, for as long as it takes. So a remote cover is
// fetched by the helper, where curl stops the producer at the socket, and what
// reaches this file is a local file that is already small.
//
// The type is then decided twice, by the same rule: the helper refuses anything
// whose magic bytes are not an image it knows, and the bytes are checked again
// here before a decoder sees them.
Item {
  id: root

  property string url: ""
  property int maxBytes: 1024 * 1024
  // The decode bound, separate from the byte bound: an image inside its budget
  // can still be enormous in pixels.
  property int decodeSize: 256

  readonly property bool local: Media.isLocalArt(url)
  readonly property bool ready: image.status === Image.Ready

  property string fetchedPath: ""

  onUrlChanged: {
    fetchedPath = ""
    verify.path = ""
    fetcher.cancel()
    // Coalesced: a player that rewrites its metadata in a loop should cost one
    // fetch, not one per write.
    if (url !== "" && !local && Media.isRemoteArt(url)) debounce.restart()
    else debounce.stop()
  }

  Timer {
    id: debounce
    interval: 250
    onTriggered: fetcher.get(root.url)
  }

  Fetcher {
    id: fetcher
    name: "art"
    kind: "image"
    maxBytes: root.maxBytes
    onFetched: function (path) {
      verify.path = path
      verify.reload()
    }
    onFailed: function (code) { root.fetchedPath = "" }
  }

  // Bounded on the way in as well: the helper wrote this file, but a read with
  // no ceiling is the thing this plugin has twice been told not to do.
  GuardedFile {
    id: verify
    binary: true
    maxBytes: root.maxBytes
    onBytesLoaded: function (bytes) {
      root.fetchedPath = Bytes.imageType(bytes) === "" ? "" : "file://" + path
    }
    onMissing: root.fetchedPath = ""
  }

  Image {
    id: image
    anchors.fill: parent
    source: root.local ? root.url : root.fetchedPath
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    sourceSize.width: root.decodeSize
    sourceSize.height: root.decodeSize
  }
}
