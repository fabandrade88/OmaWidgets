// What an image's first bytes say it is.
//
// Album art arrives as a file this plugin fetched, and the Content-Type that
// came with it is the server's claim about it. This is the file's own: a
// decoder is only ever handed something whose magic bytes match a format the
// toolkit reads.

// The formats a Qt image provider will actually decode, by their magic bytes.
// Content-Type is the server's claim; this is the file's own.
var SIGNATURES = [
  { type: "image/png", bytes: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A] },
  { type: "image/jpeg", bytes: [0xFF, 0xD8, 0xFF] },
  { type: "image/gif", bytes: [0x47, 0x49, 0x46, 0x38] },
  // WEBP is "RIFF" then four size bytes then "WEBP", so the tail is checked
  // separately below.
  { type: "image/webp", bytes: [0x52, 0x49, 0x46, 0x46] },
  { type: "image/bmp", bytes: [0x42, 0x4D] }
]

function at(bytes, index) {
  var value = bytes[index]
  return typeof value === "number" ? value & 0xFF : -1
}

function startsWith(bytes, signature) {
  for (var i = 0; i < signature.length; i++) if (at(bytes, i) !== signature[i]) return false
  return true
}

// The image type these bytes actually are, or "" — which is a refusal, not a
// guess. A server that says image/png and sends something else gets nowhere.
function imageType(bytes) {
  if (!bytes || typeof bytes.length !== "number" || bytes.length < 4) return ""
  for (var i = 0; i < SIGNATURES.length; i++) {
    if (!startsWith(bytes, SIGNATURES[i].bytes)) continue
    if (SIGNATURES[i].type !== "image/webp") return SIGNATURES[i].type
    // RIFF....WEBP
    if (bytes.length >= 12 && at(bytes, 8) === 0x57 && at(bytes, 9) === 0x45
      && at(bytes, 10) === 0x42 && at(bytes, 11) === 0x50) return "image/webp"
  }
  return ""
}

if (typeof module !== "undefined") {
  module.exports = {
    imageType: imageType
  }
}
