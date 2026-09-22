// Bytes to base64, and what an image's first bytes say it is.
//
// Both exist because album art is fetched rather than handed to an Image as a
// URL: a bounded fetch means we hold the bytes, and the only way back to an
// Image from there is a data URL. Qt.btoa cannot encode binary — it takes a
// string and encodes its UTF-8, which mangles every byte above 0x7F — so the
// encoding is done here, where node can check it against a known-good one.
var ALPHABET = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

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

function base64(bytes) {
  if (!bytes || typeof bytes.length !== "number") return ""
  var out = ""
  var length = bytes.length
  for (var i = 0; i < length; i += 3) {
    var b0 = at(bytes, i)
    var b1 = i + 1 < length ? at(bytes, i + 1) : -1
    var b2 = i + 2 < length ? at(bytes, i + 2) : -1
    out += ALPHABET[b0 >> 2]
    out += ALPHABET[((b0 & 3) << 4) | (b1 < 0 ? 0 : b1 >> 4)]
    out += b1 < 0 ? "=" : ALPHABET[((b1 & 15) << 2) | (b2 < 0 ? 0 : b2 >> 6)]
    out += b2 < 0 ? "=" : ALPHABET[b2 & 63]
  }
  return out
}

// A data URL an Image can render, or "" if these bytes are not an image this
// toolkit decodes.
function imageDataUrl(bytes) {
  var type = imageType(bytes)
  if (type === "") return ""
  var body = base64(bytes)
  return body === "" ? "" : "data:" + type + ";base64," + body
}

if (typeof module !== "undefined") {
  module.exports = {
    imageType: imageType, base64: base64, imageDataUrl: imageDataUrl
  }
}
