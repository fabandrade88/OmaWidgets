// Is there a newer version published, and where would we look.
//
// The check is a single GET of the published manifest.json. Nothing here
// installs anything: Omarchy's own `omarchy plugin update` does that, in a
// terminal, after showing the user a diff — a plugin that quietly replaced its
// own code would defeat the one review step the installer guarantees.
//
// Everything a network response touches is treated as hostile: the body is
// bounded before it is parsed, the version has to look like a version, and the
// URL is rebuilt from an allowlisted shape rather than followed as given.
var MAX_BODY = 64 * 1024
var VERSION_PATTERN = /^[0-9A-Za-z][0-9A-Za-z.+-]{0,63}$/
var ID_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$/
var GITHUB_REPO = /^https:\/\/github\.com\/([A-Za-z0-9][\w.-]{0,38})\/([\w.-]{1,100}?)(?:\.git)?\/?$/

var CURRENT = "current"
var AVAILABLE = "available"
var UNKNOWN = "unknown"

// A day. Often enough that a release is noticed, rarely enough that nobody
// would call it traffic.
var INTERVAL_MS = 24 * 60 * 60 * 1000

// Only github.com, only owner/repo, and the result is built here rather than
// taken from the manifest — so a hand-edited repository field cannot point the
// check at an arbitrary host.
function rawManifestUrl(repository) {
  var match = GITHUB_REPO.exec(String(repository || "").trim())
  if (!match) return ""
  return "https://raw.githubusercontent.com/" + match[1] + "/" + match[2] + "/HEAD/manifest.json"
}

// The plugin id as `omarchy plugin update` will accept it, or "" — the same
// shape omarchy-plugin-validate enforces.
function commandId(id) {
  var text = String(id || "")
  if (!ID_PATTERN.test(text) || text.indexOf("..") !== -1) return ""
  return text
}

function version(value) {
  var text = String(value === undefined || value === null ? "" : value).trim()
  return VERSION_PATTERN.test(text) ? text : ""
}

// The version out of a manifest body, or "" for anything that is not one.
function versionFrom(body) {
  var text = typeof body === "string" ? body : ""
  if (text === "" || text.length > MAX_BODY) return ""
  try {
    var parsed = JSON.parse(text)
    if (!parsed || typeof parsed !== "object") return ""
    return version(parsed.version)
  } catch (e) {
    return ""
  }
}

function parts(value) {
  var out = []
  var chunks = String(value || "").split(/[.+-]/)
  for (var i = 0; i < chunks.length; i++) {
    var n = parseInt(chunks[i], 10)
    out.push(isFinite(n) ? n : 0)
  }
  return out
}

// -1, 0 or 1. Numeric segment by segment, so 1.10.0 is above 1.9.0 and a
// missing segment counts as zero.
function compare(a, b) {
  var left = parts(a)
  var right = parts(b)
  var length = Math.max(left.length, right.length)
  for (var i = 0; i < length; i++) {
    var l = i < left.length ? left[i] : 0
    var r = i < right.length ? right[i] : 0
    if (l !== r) return l > r ? 1 : -1
  }
  return 0
}

// What to tell the user. An unreadable or absent answer is "unknown", never
// "up to date": silence is not the same as a clean bill of health.
function describe(installed, latest) {
  var here = version(installed)
  var there = version(latest)
  if (here === "" || there === "") return { state: UNKNOWN, latest: there }
  return { state: compare(there, here) > 0 ? AVAILABLE : CURRENT, latest: there }
}

function dueForCheck(lastChecked, now, intervalMs) {
  var last = typeof lastChecked === "number" && isFinite(lastChecked) ? lastChecked : 0
  var at = typeof now === "number" && isFinite(now) ? now : 0
  var gap = typeof intervalMs === "number" && isFinite(intervalMs) && intervalMs > 0
    ? intervalMs : INTERVAL_MS
  // A clock that went backwards (a suspend, a timezone fix) should produce a
  // check, not a wait until the old timestamp catches up.
  if (last > at) return true
  return at - last >= gap
}

if (typeof module !== "undefined") {
  module.exports = {
    CURRENT: CURRENT, AVAILABLE: AVAILABLE, UNKNOWN: UNKNOWN,
    MAX_BODY: MAX_BODY, INTERVAL_MS: INTERVAL_MS,
    rawManifestUrl: rawManifestUrl,
    commandId: commandId,
    version: version,
    versionFrom: versionFrom,
    compare: compare,
    describe: describe,
    dueForCheck: dueForCheck
  }
}
