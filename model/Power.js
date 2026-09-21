// Battery presentation and the power-profile allowlist.
//
// Setting a profile is the only thing this plugin does that changes system
// state, so the value that reaches a command line is gated twice: it must be one
// of the three names power-profiles-daemon defines, AND it must appear in the
// list the running daemon reported for this machine. sanitizeProfile is the only
// way a profile name leaves this file, and it returns "" rather than passing
// anything it does not recognise.
var UNKNOWN = -1

var SAVER = "power-saver"
var BALANCED = "balanced"
var PERFORMANCE = "performance"

// The complete set, in the order power-profiles-daemon defines them. Nothing
// outside this array is ever a valid profile, whatever the daemon replies.
var KNOWN_PROFILES = [SAVER, BALANCED, PERFORMANCE]

var LABELS = {}
LABELS[SAVER] = "Saver"
LABELS[BALANCED] = "Balanced"
LABELS[PERFORMANCE] = "Performance"

var DESCRIPTIONS = {}
DESCRIPTIONS[SAVER] = "Longest runtime, lowest clocks"
DESCRIPTIONS[BALANCED] = "The default trade-off"
DESCRIPTIONS[PERFORMANCE] = "Highest clocks, shortest runtime"

var ICONS = {}
ICONS[SAVER] = "󰌪"
ICONS[BALANCED] = "󰊚"
ICONS[PERFORMANCE] = "󰓅"

function isKnownProfile(value) {
  return KNOWN_PROFILES.indexOf(String(value || "")) !== -1
}

// Two gates: the hard-coded set, then what this machine actually offers. A
// desktop without power-profiles-daemon offers nothing, so nothing passes.
function sanitizeProfile(value, available) {
  var name = String(value || "").trim()
  if (!isKnownProfile(name)) return ""
  var list = Array.isArray(available) ? available : []
  if (list.length === 0) return ""
  return list.indexOf(name) !== -1 ? name : ""
}

// `omarchy-powerprofiles-list --active-state` prints "<name>\t<0|1>" per line,
// highest-performance first. Unknown names are dropped rather than shown as a
// button that cannot be pressed safely.
function parseProfileList(raw) {
  var lines = String(raw || "").split("\n")
  var profiles = []
  var active = ""
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (line === "") continue
    var fields = line.split("\t")
    var name = String(fields[0] || "").trim()
    if (!isKnownProfile(name) || profiles.indexOf(name) !== -1) continue
    profiles.push(name)
    if (String(fields[1] || "").trim() === "1") active = name
  }
  // Present them saver -> performance so the control reads left to right like a
  // slider, regardless of the order the daemon listed them in.
  profiles.sort(function (a, b) {
    return KNOWN_PROFILES.indexOf(a) - KNOWN_PROFILES.indexOf(b)
  })
  return { profiles: profiles, active: active }
}

// `busctl get-property ... ActiveProfile` replies with: s "balanced"
function parseActiveProfile(raw) {
  var match = String(raw || "").match(/"([^"]*)"/)
  var name = match ? match[1] : ""
  return isKnownProfile(name) ? name : ""
}

// Where the next profile is. Two behaviours on purpose: a tile has one gesture,
// so tapping it cycles and wraps round to the start; arrow keys in the popup
// step and stop at the ends, the way arrow keys on a slider do.
function nextProfileIndex(profiles, active, delta, wrap) {
  var list = Array.isArray(profiles) ? profiles : []
  if (list.length === 0) return -1
  var at = list.indexOf(String(active || ""))
  var step = delta < 0 ? -1 : 1
  if (at < 0) return delta < 0 ? list.length - 1 : 0
  if (wrap) return (at + step + list.length) % list.length
  return Math.max(0, Math.min(list.length - 1, at + step))
}

function profileLabel(name) { return LABELS[name] || String(name || "") }
function profileDescription(name) { return DESCRIPTIONS[name] || "" }
function profileIcon(name) { return ICONS[name] || ICONS[BALANCED] }

// Nerd Font battery ramp, matching the stock Omarchy power widget so a theme
// tuned for one is tuned for both.
var DISCHARGING_ICONS = ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾",
  "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
var CHARGING_ICONS = ["󰊣", "󰂆", "󰂇", "󰂈", "󰊢",
  "󰂉", "󰊤", "󰂊", "󰂋", "󰂅"]

function batteryIcon(fraction, charging) {
  var value = typeof fraction === "number" && isFinite(fraction) ? fraction : 0
  var index = Math.max(0, Math.min(9, Math.floor(Math.max(0, Math.min(1, value)) * 10)))
  return charging ? CHARGING_ICONS[index] : DISCHARGING_ICONS[index]
}

// Health is the one battery number that changes over years rather than minutes,
// which makes a worn cell worth calling out on its own line.
function healthLabel(healthPercent) {
  var value = typeof healthPercent === "number" && isFinite(healthPercent) ? healthPercent : 0
  if (value <= 0 || value > 100) return ""
  return Math.round(value) + "% health"
}

// Below this the card switches to the theme's urgent colour.
var LOW_FRACTION = 0.2

function isLow(fraction, charging) {
  if (charging) return false
  return typeof fraction === "number" && isFinite(fraction) && fraction <= LOW_FRACTION
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    SAVER: SAVER, BALANCED: BALANCED, PERFORMANCE: PERFORMANCE,
    KNOWN_PROFILES: KNOWN_PROFILES,
    LOW_FRACTION: LOW_FRACTION,
    isKnownProfile: isKnownProfile,
    sanitizeProfile: sanitizeProfile,
    parseProfileList: parseProfileList,
    parseActiveProfile: parseActiveProfile,
    nextProfileIndex: nextProfileIndex,
    profileLabel: profileLabel,
    profileDescription: profileDescription,
    profileIcon: profileIcon,
    batteryIcon: batteryIcon,
    healthLabel: healthLabel,
    isLow: isLow
  }
}
