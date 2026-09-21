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
var CARD_TODO = "todo"

// Compact draws one tile per card, not one per reading: the Performance tile is
// a wide rectangle holding CPU, memory and GPU together, rather than three
// separate squares. Keeping tiles and cards one to one is also what lets the
// same drag reorder both layouts.
var TILE_SPANS = {}
TILE_SPANS[CARD_SYSTEM] = 2

var LABELS = {}
LABELS[CARD_SYSTEM] = "PERFORMANCE"
LABELS[CARD_MEDIA] = "NOW PLAYING"
LABELS[CARD_PODS] = "AIRPODS"
LABELS[CARD_BATTERY] = "BATTERY"
LABELS[CARD_POWER] = "POWER"
LABELS[CARD_TODO] = "TO-DO"

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

// How many columns a tile occupies. Everything is one column wide except the
// Performance tile, which carries three readings and needs the room.
function tileSpan(id) {
  return TILE_SPANS[String(id || "")] || 1
}

function tileLabel(id) {
  return LABELS[String(id || "")] || ""
}

// How many cards of `cardWidth` fit side by side in `available` pixels, given
// `spacing` between them. The overlay has the whole screen and wants one row,
// but six full cards are wider than a 1600px display and a column count that
// does not fit is drawn clipped at both edges rather than wrapped.
//
// Returns at least 1: one clipped card still beats none, and a surface that has
// not been laid out yet reports a width of 0.
function columnsThatFit(available, cardWidth, spacing, count) {
  var total = Math.max(1, Number(count) || 1)
  var width = Number(cardWidth)
  var gap = Number(spacing) || 0
  if (!(width > 0) || !(Number(available) > 0)) return total
  var fits = Math.floor((Number(available) + gap) / (width + gap))
  return Math.max(1, Math.min(total, fits))
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
    CARD_POWER: CARD_POWER, CARD_MEDIA: CARD_MEDIA, CARD_TODO: CARD_TODO,
    TILE_SPANS: TILE_SPANS,
    POSITIONS: POSITIONS,
    defaultState: defaultState,
    visibleCards: visibleCards,
    tileSpan: tileSpan,
    tileLabel: tileLabel,
    columnsThatFit: columnsThatFit,
    anchorsFor: anchorsFor
  }
}
