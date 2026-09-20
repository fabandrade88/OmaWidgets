// Number and unit formatting shared by every card. Pure functions with no QML
// imports, so the same code runs under `node` in tests/.

// Every reading in this plugin originates in a file under /proc or /sys, or in
// a daemon-written JSON file. All of it is untrusted text: a kernel can rename
// a field, a daemon can write a partial line, a sysfs node can return an empty
// string while a device powers down. toNumber is the single gate all of it
// passes through, so no NaN ever reaches a binding.
var UNKNOWN = -1

function toNumber(raw, fallback) {
  if (typeof raw === "number") return isFinite(raw) ? raw : fallback
  var text = String(raw === undefined || raw === null ? "" : raw).trim()
  if (text === "") return fallback
  var n = Number(text)
  return isFinite(n) ? n : fallback
}

function toInt(raw, fallback) {
  var n = toNumber(raw, NaN)
  return isFinite(n) ? Math.round(n) : fallback
}

function clamp(value, min, max) {
  var n = toNumber(value, min)
  return Math.max(min, Math.min(max, n))
}

function fraction(value) {
  return clamp(value, 0, 1)
}

function isKnown(value) {
  return typeof value === "number" && isFinite(value) && value > UNKNOWN
}

// 0..1 -> "42%". Percentages are rounded, never truncated: a 99.6% full disk
// reading "99%" invites a second look at a number that is already settled.
function percent(value, digits) {
  var pct = fraction(value) * 100
  return (digits > 0 ? pct.toFixed(digits) : String(Math.round(pct))) + "%"
}

function percentOf(value) {
  return Math.round(fraction(value) * 100)
}

// Kibibytes (the unit /proc/meminfo speaks) -> "12.4 GB". Two significant
// figures below 10 so a card row does not jitter in width each sample.
function fromKib(kib) {
  var mib = toNumber(kib, 0) / 1024
  if (mib < 1024) return Math.round(mib) + " MB"
  var gib = mib / 1024
  return (gib < 10 ? gib.toFixed(1) : String(Math.round(gib))) + " GB"
}

// Mebibytes, for GPU VRAM, which every driver reports in MiB.
function fromMib(mib) {
  return fromKib(toNumber(mib, 0) * 1024)
}

// hwmon and thermal_zone both report millidegrees Celsius.
function celsius(milli) {
  var value = toNumber(milli, NaN)
  if (!isFinite(value)) return ""
  return Math.round(value / 1000) + "°"
}

function megahertz(mhz) {
  var value = toNumber(mhz, NaN)
  if (!isFinite(value) || value <= 0) return ""
  if (value >= 1000) return (value / 1000).toFixed(1) + " GHz"
  return Math.round(value) + " MHz"
}

function watts(value) {
  var n = toNumber(value, NaN)
  if (!isFinite(n)) return ""
  return (Math.abs(n) < 10 ? Math.abs(n).toFixed(1) : String(Math.round(Math.abs(n)))) + " W"
}

// Seconds -> "2h 14m" / "47m". UPower reports 0 when it has no estimate yet,
// which is not the same as "no time left", so it yields "" rather than "0m".
function duration(seconds) {
  var total = toInt(seconds, 0)
  if (total <= 0) return ""
  var hours = Math.floor(total / 3600)
  var minutes = Math.round((total - hours * 3600) / 60)
  if (minutes === 60) { hours += 1; minutes = 0 }
  if (hours <= 0) return minutes + "m"
  return minutes > 0 ? hours + "h " + minutes + "m" : hours + "h"
}

// Joins the parts of a meta line, dropping the ones that had no reading. Every
// card builds its subtitle this way so a missing sensor leaves no stray
// separator behind.
function joinMeta(parts, separator) {
  var out = []
  for (var i = 0; i < parts.length; i++) {
    var part = String(parts[i] === undefined || parts[i] === null ? "" : parts[i]).trim()
    if (part !== "") out.push(part)
  }
  return out.join(separator || " · ")
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    toNumber: toNumber,
    toInt: toInt,
    clamp: clamp,
    fraction: fraction,
    isKnown: isKnown,
    percent: percent,
    percentOf: percentOf,
    fromKib: fromKib,
    fromMib: fromMib,
    celsius: celsius,
    megahertz: megahertz,
    watts: watts,
    duration: duration,
    joinMeta: joinMeta
  }
}
