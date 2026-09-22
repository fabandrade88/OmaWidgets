// Bytes to base64, and what a byte stream is allowed to become.
var t = require("./harness.js")
var crypto = require("crypto")
var Bytes = require("../model/Bytes.js")
var Media = require("../model/Media.js")

// Checked against node's own encoder at every length, because the padding is
// where a hand-written base64 goes wrong and a wrong data URL is an image that
// silently fails to appear.
var lengths = [0, 1, 2, 3, 4, 5, 6, 7, 8, 63, 64, 65, 255, 256, 1000]
var matched = 0
for (var i = 0; i < lengths.length; i++) {
  var buffer = crypto.randomBytes(lengths[i])
  if (Bytes.base64(Array.from(buffer)) === buffer.toString("base64")) matched += 1
}
t.eq(matched, lengths.length, "base64 matches node's encoder at every length tried")
t.eq(Bytes.base64([]), "", "no bytes encode to nothing")
t.eq(Bytes.base64(null), "", "and neither does nothing at all")

// The type is the file's own claim, not the server's.
var PNG = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0, 0, 0, 13]
var JPEG = [0xFF, 0xD8, 0xFF, 0xE0, 0, 16]
var GIF = [0x47, 0x49, 0x46, 0x38, 0x39, 0x61]
var WEBP = [0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x45, 0x42, 0x50]
var RIFF_WAV = [0x52, 0x49, 0x46, 0x46, 1, 2, 3, 4, 0x57, 0x41, 0x56, 0x45]
var HTML = [0x3C, 0x68, 0x74, 0x6D, 0x6C, 0x3E]
var SVG = [0x3C, 0x73, 0x76, 0x67, 0x20]
var ELF = [0x7F, 0x45, 0x4C, 0x46]

t.eq(Bytes.imageType(PNG), "image/png", "a PNG says so in its first eight bytes")
t.eq(Bytes.imageType(JPEG), "image/jpeg", "a JPEG in its first three")
t.eq(Bytes.imageType(GIF), "image/gif", "a GIF in its first four")
t.eq(Bytes.imageType(WEBP), "image/webp", "a WebP in its first twelve")
t.eq(Bytes.imageType(RIFF_WAV), "", "a RIFF container that is not WebP is not an image")
t.eq(Bytes.imageType(HTML), "", "an error page served as image/png is not an image")
t.eq(Bytes.imageType(SVG), "", "and neither is SVG, which is a document with scripting")
t.eq(Bytes.imageType(ELF), "", "or an executable")
t.eq(Bytes.imageType([0x89]), "", "too few bytes to tell is not a yes")
t.eq(Bytes.imageType(null), "", "nothing is not an image")

t.ok(Bytes.imageDataUrl(PNG).indexOf("data:image/png;base64,") === 0,
  "an image becomes a data URL an Image can render")
t.eq(Bytes.imageDataUrl(HTML), "", "anything else becomes nothing, not a data URL")

// Which URLs are fetched with a ceiling and which are read off disk.
t.eq(Media.isLocalArt("file:///home/x/cover.png"), true, "file art is local")
t.eq(Media.isLocalArt("https://i.scdn.co/image/ab"), false, "https art is not")
t.eq(Media.isRemoteArt("https://i.scdn.co/image/ab"), true, "and is fetched instead")
t.eq(Media.isLocalArt("FILE:///home/x/cover.png"), true, "the scheme is matched whatever its case")
t.eq(Media.isLocalArt(""), false, "no art is not local art")

process.exit(t.report("bytes"))
