import QtQuick
import "../services"
import "../model/Bytes.js" as Bytes
import "../model/Media.js" as Media

// Album art, fetched with a ceiling rather than handed to an Image as a URL.
//
// The URL comes from whatever application registered itself on MPRIS, so it is
// attacker-influenced in the ordinary sense: any process on the session bus can
// publish one. An Image given a remote URL downloads whatever arrives, with no
// limit on how long it takes or how much of it is kept, so remote art goes
// through BoundedFetch instead and reaches the Image as bytes we have already
// agreed to hold.
//
// Local art — the `file://` URLs local players publish — is loaded directly.
// It is a file on this machine, read by the same toolkit that reads every other
// file, and fetching it over HTTP to bound it would be theatre.
Item {
  id: root

  property string url: ""
  property int maxBytes: 1024 * 1024
  // The decode bound, separate from the download bound: an image that arrives
  // inside its byte budget can still be enormous in pixels.
  property int decodeSize: 256
  property int radius: 0
  property bool rounded: false

  readonly property bool local: Media.isLocalArt(url)
  readonly property bool ready: image.status === Image.Ready

  property string dataUrl: ""

  onUrlChanged: {
    dataUrl = ""
    fetch.cancel()
    if (url !== "" && !local) fetch.get(url)
  }

  BoundedFetch {
    id: fetch
    mode: "bytes"
    maxBytes: root.maxBytes
    timeoutMs: 6000
    // What the bytes are is decided by the bytes, not by the Content-Type the
    // server claimed: anything that is not an image this toolkit decodes is
    // dropped without ever reaching one.
    onLoaded: function (text, bytes) { root.dataUrl = Bytes.imageDataUrl(bytes) }
    onFailed: function (reason) { root.dataUrl = "" }
  }

  Image {
    id: image
    anchors.fill: parent
    source: root.local ? root.url : root.dataUrl
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    sourceSize.width: root.decodeSize
    sourceSize.height: root.decodeSize
  }
}
