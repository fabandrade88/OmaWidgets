// How the AirPods readings are described, as against how they are parsed.
//
// Split from Pods.js so the file format and the presentation can be read apart
// from one another; both are standalone, with no QML imports, so `node` loads
// them unchanged.
var UNKNOWN = -1

var NOISE_OFF = 0
var NOISE_ANC = 1
var NOISE_TRANSPARENCY = 2
var NOISE_ADAPTIVE = 3

var LID_OPEN = 0
var LID_CLOSED = 1

var NOISE_NAMES = {}
NOISE_NAMES[NOISE_OFF] = "Off"
NOISE_NAMES[NOISE_ANC] = "Noise Cancellation"
NOISE_NAMES[NOISE_TRANSPARENCY] = "Transparency"
NOISE_NAMES[NOISE_ADAPTIVE] = "Adaptive"

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
    noiseModeName: noiseModeName,
    lidName: lidName,
    hasAnyBattery: hasAnyBattery,
    lowestPodLevel: lowestPodLevel
  }
}
