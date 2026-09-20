// Reader for the librepods status file that the AirPods plugin's daemon
// publishes at $XDG_STATE_HOME/librepods/status.json.
//
// This is a read-only consumer. Listening mode, ear detection and the rest of
// the controls belong to io.github.thisisgm.omapods, which owns the write path
// to the daemon; duplicating those writes here would mean two panels racing
// each other's optimistic state for the same device. So this card displays and
// does not command.
//
// The file is treated as untrusted input throughout: it is written by a separate
// process that can be mid-write, a version behind, or absent entirely. Every
// field is type-checked and every level is clamped before it reaches a binding.
var UNKNOWN = -1
var SUPPORTED_SCHEMA = 1

var NOISE_UNKNOWN = -1
var NOISE_OFF = 0
var NOISE_ANC = 1
var NOISE_TRANSPARENCY = 2
var NOISE_ADAPTIVE = 3

var LID_OPEN = 0
var LID_CLOSED = 1
var LID_UNKNOWN = 2

var NOISE_NAMES = {}
NOISE_NAMES[NOISE_OFF] = "Off"
NOISE_NAMES[NOISE_ANC] = "Noise Cancellation"
NOISE_NAMES[NOISE_TRANSPARENCY] = "Transparency"
NOISE_NAMES[NOISE_ADAPTIVE] = "Adaptive"

function level(raw) {
  if (typeof raw !== "number" || !isFinite(raw)) return UNKNOWN
  var rounded = Math.round(raw)
  return rounded < 0 || rounded > 100 ? UNKNOWN : rounded
}

function emptyPod() {
  return { available: false, level: UNKNOWN, charging: false, inEar: false }
}

function pod(raw) {
  var out = emptyPod()
  if (!raw || typeof raw !== "object") return out
  // available:false means the daemon has stopped hearing from this pod, which
  // makes its charging and in-ear flags stale too — not false.
  if (raw.available !== true) return out
  out.available = true
  out.level = level(raw.level)
  out.charging = raw.charging === true
  out.inEar = raw.in_ear === true
  return out
}

function empty() {
  return {
    ok: false,
    error: "",
    schemaTooNew: false,
    daemonRunning: false,
    connected: false,
    deviceName: "",
    modelName: "",
    isHeadset: false,
    isProSeries: false,
    noiseMode: NOISE_UNKNOWN,
    adaptiveLevel: UNKNOWN,
    lidState: LID_UNKNOWN,
    left: emptyPod(),
    right: emptyPod(),
    caseBattery: emptyPod(),
    headset: emptyPod()
  }
}

function parse(raw) {
  var status = empty()
  var text = String(raw || "").trim()
  if (text === "") {
    status.error = "The librepods status file is empty"
    return status
  }

  var parsed
  try {
    parsed = JSON.parse(text)
  } catch (e) {
    // A file caught mid-write still proves the daemon is running.
    status.daemonRunning = true
    status.error = "Could not read the librepods status file"
    return status
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    status.daemonRunning = true
    status.error = "The librepods status file is not an object"
    return status
  }

  status.daemonRunning = true
  var schema = typeof parsed.schema_version === "number" ? parsed.schema_version : 0
  if (schema > SUPPORTED_SCHEMA) {
    status.schemaTooNew = true
    status.error = "The librepods daemon speaks a newer status format"
    return status
  }

  status.ok = true
  status.connected = parsed.connected === true
  status.deviceName = text_(parsed.device_name)
  status.modelName = text_(parsed.model_name)
  status.isHeadset = parsed.is_headset === true
  status.isProSeries = parsed.is_pro_series === true
  status.noiseMode = mode(parsed.noise_mode)
  status.adaptiveLevel = level(parsed.adaptive_noise_level)
  status.lidState = lid(parsed.lid_state)
  status.left = pod(parsed.left)
  status.right = pod(parsed.right)
  status.caseBattery = pod(parsed["case"])
  status.headset = pod(parsed.headset)
  return status
}

// Device and model names come from the device itself over Bluetooth, so they are
// attacker-influenced strings. They are only ever rendered as PlainText, and the
// length cap keeps a hostile name from stretching a card off the screen.
function text_(raw) {
  if (typeof raw !== "string") return ""
  return raw.replace(/[\u0000-\u001F\u007F]/g, "").slice(0, 64)
}

function mode(raw) {
  if (typeof raw !== "number" || !isFinite(raw)) return NOISE_UNKNOWN
  var value = Math.round(raw)
  return value >= NOISE_OFF && value <= NOISE_ADAPTIVE ? value : NOISE_UNKNOWN
}

function lid(raw) {
  if (typeof raw !== "number" || !isFinite(raw)) return LID_UNKNOWN
  var value = Math.round(raw)
  return value === LID_OPEN || value === LID_CLOSED ? value : LID_UNKNOWN
}

function noiseModeName(value) {
  return NOISE_NAMES[value] || ""
}

function lidName(value) {
  if (value === LID_OPEN) return "Case open"
  if (value === LID_CLOSED) return "Case closed"
  return ""
}

// Battery keeps arriving over BLE advertisements while the audio link is down,
// so a card can be worth drawing even when `connected` is false.
function hasAnyBattery(status) {
  if (!status || !status.ok) return false
  if (status.isHeadset) return status.headset.level > UNKNOWN
  return status.left.level > UNKNOWN || status.right.level > UNKNOWN
    || status.caseBattery.level > UNKNOWN
}

// The lowest pod reading is what tells you whether you can start a call, so it
// is what the card leads with. The case is excluded: a flat case does not stop
// you listening.
function lowestPodLevel(status) {
  if (!status || !status.ok) return UNKNOWN
  var levels = status.isHeadset
    ? [status.headset.level]
    : [status.left.level, status.right.level]
  var lowest = UNKNOWN
  for (var i = 0; i < levels.length; i++) {
    if (levels[i] <= UNKNOWN) continue
    if (lowest === UNKNOWN || levels[i] < lowest) lowest = levels[i]
  }
  return lowest
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    SUPPORTED_SCHEMA: SUPPORTED_SCHEMA,
    NOISE_UNKNOWN: NOISE_UNKNOWN, NOISE_OFF: NOISE_OFF, NOISE_ANC: NOISE_ANC,
    NOISE_TRANSPARENCY: NOISE_TRANSPARENCY, NOISE_ADAPTIVE: NOISE_ADAPTIVE,
    LID_OPEN: LID_OPEN, LID_CLOSED: LID_CLOSED, LID_UNKNOWN: LID_UNKNOWN,
    empty: empty,
    emptyPod: emptyPod,
    parse: parse,
    noiseModeName: noiseModeName,
    lidName: lidName,
    hasAnyBattery: hasAnyBattery,
    lowestPodLevel: lowestPodLevel
  }
}
