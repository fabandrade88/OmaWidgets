// Parser for the key/tab/value block that scripts/omawidgets-probe prints.
//
// The script is ours and takes no input, but its output is still parsed
// defensively: a machine where a sysfs layout changed mid-release should lose one
// row of one card, not break the plugin. Unknown keys are kept (harmless), a line
// without a tab is dropped, and every lookup has a typed accessor with a
// fallback so a caller never handles undefined.
var MAX_LINES = 200
var MAX_VALUE_LENGTH = 512
// The probe's whole output. A value this side of a megabyte is already absurd
// for a list of sysfs paths; refusing outright beats splitting it first.
var MAX_OUTPUT = 64 * 1024

// The only programs this plugin will run from a discovered path. A path that is
// read is one thing; a path that is executed is another, and it gets its own
// list rather than sharing the sysfs one — which is what silently disabled
// NVIDIA support, since /usr/bin/nvidia-smi is under neither /sys nor /proc.
var PROGRAMS = ["/usr/bin/nvidia-smi"]

function parse(raw) {
  var values = {}
  var text = String(raw || "")
  if (text.length > MAX_OUTPUT) return values
  var lines = text.split("\n")
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

// An executable. Matched against the list above rather than pattern-checked:
// there are two of them, and an exact match cannot be talked around.
function program(values, key) {
  var value = text(values, key, "")
  return PROGRAMS.indexOf(value) !== -1 ? value : ""
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
  module.exports = { MAX_OUTPUT: MAX_OUTPUT, PROGRAMS: PROGRAMS,
    parse: parse, text: text, path: path, program: program,
    number: number, flag: flag }
}
