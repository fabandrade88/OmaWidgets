// Parser for the key/tab/value block that scripts/omawidgets-probe prints.
//
// The script is ours and takes no input, but its output is still parsed
// defensively: a machine where a sysfs layout changed mid-release should lose one
// row of one card, not break the plugin. Unknown keys are kept (harmless), a line
// without a tab is dropped, and every lookup has a typed accessor with a
// fallback so a caller never handles undefined.
var MAX_LINES = 200
var MAX_VALUE_LENGTH = 512

function parse(raw) {
  var values = {}
  var lines = String(raw || "").split("\n")
  var count = Math.min(lines.length, MAX_LINES)
  for (var i = 0; i < count; i++) {
    var separator = lines[i].indexOf("\t")
    if (separator <= 0) continue
    var key = lines[i].substring(0, separator).trim()
    if (key === "") continue
    values[key] = lines[i].substring(separator + 1).trim().slice(0, MAX_VALUE_LENGTH)
  }
  return values
}

function text(values, key, fallback) {
  var value = values && typeof values === "object" ? values[String(key)] : undefined
  return typeof value === "string" && value !== "" ? value : String(fallback === undefined ? "" : fallback)
}

// A discovered path. The script already confirmed it is a readable regular file
// under /sys or /proc; this is the second check, so a path that somehow arrived
// from anywhere else never reaches a FileView.
function path(values, key) {
  var value = text(values, key, "")
  if (value === "") return ""
  if (value.indexOf("/sys/") !== 0 && value.indexOf("/proc/") !== 0) return ""
  if (value.indexOf("..") !== -1) return ""
  return value
}

function number(values, key, fallback) {
  // An absent key yields "", and Number("") is 0 rather than NaN, so the empty
  // case is caught before the coercion.
  var raw = text(values, key, "")
  if (raw === "") return fallback
  var n = Number(raw)
  return isFinite(n) ? n : fallback
}

function flag(values, key) {
  return text(values, key, "") === "1"
}

if (typeof module !== "undefined") {
  module.exports = { parse: parse, text: text, path: path, number: number, flag: flag }
}
