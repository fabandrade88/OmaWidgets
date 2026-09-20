// Arrangement: which cards are worth drawing, what they become in compact mode,
// and where the desktop window anchors.
//
// Split from Settings.js, which validates values. This file decides placement,
// and keeps that decision out of the surfaces so two of them cannot disagree
// about it — the overlay sizes itself from the same answer the stack lays out.
var CARD_SYSTEM = "system"
var CARD_PODS = "pods"
var CARD_BATTERY = "battery"
var CARD_POWER = "power"
var CARD_MEDIA = "media"

var TILE_CPU = "cpu"
var TILE_MEMORY = "memory"
var TILE_GPU = "gpu"
var TILE_PODS = "pods"
var TILE_BATTERY = "battery"
var TILE_POWER = "power"
var TILE_MEDIA = "media"

// Compact mode is not the same card with less padding: the Performance card
// carries three unrelated readings, and at tile size each one deserves its own
// square rather than being crushed together.
var CARD_TILES = {}
CARD_TILES[CARD_SYSTEM] = [TILE_CPU, TILE_MEMORY, TILE_GPU]
CARD_TILES[CARD_PODS] = [TILE_PODS]
CARD_TILES[CARD_BATTERY] = [TILE_BATTERY]
CARD_TILES[CARD_POWER] = [TILE_POWER]
CARD_TILES[CARD_MEDIA] = [TILE_MEDIA]

var TILE_LABELS = {}
TILE_LABELS[TILE_CPU] = "CPU"
TILE_LABELS[TILE_MEMORY] = "RAM"
TILE_LABELS[TILE_GPU] = "GPU"
TILE_LABELS[TILE_PODS] = "PODS"
TILE_LABELS[TILE_BATTERY] = "BATTERY"
TILE_LABELS[TILE_POWER] = "POWER"
TILE_LABELS[TILE_MEDIA] = "NOW PLAYING"

var POSITIONS = [
  "top-left", "top-center", "top-right",
  "middle-left", "middle-right",
  "bottom-left", "bottom-center", "bottom-right"
]

// `state` says what each card's subject is currently reporting, so a card whose
// subject is absent can be dropped rather than shown empty. A machine with no
// AirPods daemon and nothing playing should carry neither card.
function defaultState() {
  return { hasPods: false, hasMedia: false }
}

function isPresent(id, settings, state) {
  var live = state || defaultState()
  if (id === CARD_PODS) return !settings.hidePodsWhenAbsent || live.hasPods === true
  if (id === CARD_MEDIA) return !settings.hideMediaWhenIdle || live.hasMedia === true
  return true
}

function visibleCards(settings, state) {
  var wanted = settings && Array.isArray(settings.cards) ? settings.cards : []
  var out = []
  for (var i = 0; i < wanted.length; i++) {
    if (isPresent(wanted[i], settings, state)) out.push(wanted[i])
  }
  return out
}

// The same list, expanded into tiles and in the same order.
function visibleTiles(settings, state) {
  var cards = visibleCards(settings, state)
  var out = []
  for (var i = 0; i < cards.length; i++) {
    var tiles = CARD_TILES[cards[i]] || []
    for (var t = 0; t < tiles.length; t++) out.push(tiles[t])
  }
  return out
}

function tileLabel(id) {
  return TILE_LABELS[String(id || "")] || ""
}

// Which screen edges the desktop window anchors to. Anchoring to one edge only
// is what makes layer-shell centre the surface along it, so the "-center" and
// "middle-" positions are expressed by leaving the opposite pair unset rather
// than by any arithmetic here.
function anchorsFor(position) {
  var name = POSITIONS.indexOf(String(position)) !== -1 ? String(position) : POSITIONS[2]
  var parts = name.split("-")
  return {
    top: parts[0] === "top",
    bottom: parts[0] === "bottom",
    left: parts[1] === "left",
    right: parts[1] === "right"
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    CARD_SYSTEM: CARD_SYSTEM, CARD_PODS: CARD_PODS, CARD_BATTERY: CARD_BATTERY,
    CARD_POWER: CARD_POWER, CARD_MEDIA: CARD_MEDIA,
    TILE_CPU: TILE_CPU, TILE_MEMORY: TILE_MEMORY, TILE_GPU: TILE_GPU,
    TILE_PODS: TILE_PODS, TILE_BATTERY: TILE_BATTERY, TILE_POWER: TILE_POWER,
    TILE_MEDIA: TILE_MEDIA,
    CARD_TILES: CARD_TILES,
    POSITIONS: POSITIONS,
    defaultState: defaultState,
    visibleCards: visibleCards,
    visibleTiles: visibleTiles,
    tileLabel: tileLabel,
    anchorsFor: anchorsFor
  }
}
