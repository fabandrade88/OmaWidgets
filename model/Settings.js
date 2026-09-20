// Settings normalisation and desktop placement maths.
//
// Everything here treats the stored settings object as untrusted: it is JSON a
// user (or another tool) edited by hand in ~/.config/omarchy/shell.json. A
// string where a number belongs, a negative width, an unknown card id or a
// position that does not exist must all produce a working widget rather than a
// broken binding, so every field is coerced and clamped and unknown values fall
// back to the default.
var CARD_SYSTEM = "system"
var CARD_PODS = "pods"
var CARD_BATTERY = "battery"
var CARD_POWER = "power"

var KNOWN_CARDS = [CARD_SYSTEM, CARD_PODS, CARD_BATTERY, CARD_POWER]

var CARD_NAMES = {}
CARD_NAMES[CARD_SYSTEM] = "Performance"
CARD_NAMES[CARD_PODS] = "AirPods"
CARD_NAMES[CARD_BATTERY] = "Battery"
CARD_NAMES[CARD_POWER] = "Power profile"

var POSITIONS = [
  "top-left", "top-center", "top-right",
  "middle-left", "middle-right",
  "bottom-left", "bottom-center", "bottom-right"
]

var DEFAULTS = {
  desktop: true,
  position: "top-right",
  marginX: 28,
  marginY: 20,
  cardWidth: 268,
  spacing: 10,
  columns: 1,
  opacity: 0.92,
  compact: false,
  intervalMs: 2000,
  cards: KNOWN_CARDS.slice(),
  monitor: "",
  hidePodsWhenAbsent: true,
  showCoreBars: true
}

function bool(value, fallback) {
  if (value === true || value === false) return value
  if (value === "true") return true
  if (value === "false") return false
  return fallback
}

// Number("") is 0, not NaN, so an absent field has to be caught before the
// coercion — otherwise every missing number clamps to its minimum instead of
// falling back to its default.
function toNumber(value) {
  if (typeof value === "number") return isFinite(value) ? value : NaN
  if (value === undefined || value === null) return NaN
  var text = String(value).trim()
  if (text === "") return NaN
  return Number(text)
}

function int(value, fallback, min, max) {
  var n = toNumber(value)
  if (!isFinite(n)) return fallback
  return Math.max(min, Math.min(max, Math.round(n)))
}

function real(value, fallback, min, max) {
  var n = toNumber(value)
  if (!isFinite(n)) return fallback
  return Math.max(min, Math.min(max, n))
}

// Card order is the user's, but the set is ours: unknown ids are dropped and
// duplicates collapse, so a hand-edited list can never make the same card
// render twice or point at a component that does not exist.
function cardList(value) {
  if (!Array.isArray(value)) return DEFAULTS.cards.slice()
  var out = []
  for (var i = 0; i < value.length; i++) {
    var id = String(value[i] || "").trim()
    if (KNOWN_CARDS.indexOf(id) !== -1 && out.indexOf(id) === -1) out.push(id)
  }
  return out
}

// A monitor name reaches Quickshell's screen matcher, never a shell, so the only
// thing to enforce is a sane length and no control characters.
function monitorName(value) {
  return String(value === undefined || value === null ? "" : value)
    .replace(/[\u0000-\u001F\u007F]/g, "").trim().slice(0, 64)
}

function normalize(raw) {
  var source = raw && typeof raw === "object" ? raw : {}
  var position = String(source.position || "").trim()
  return {
    desktop: bool(source.desktop, DEFAULTS.desktop),
    position: POSITIONS.indexOf(position) !== -1 ? position : DEFAULTS.position,
    marginX: int(source.marginX, DEFAULTS.marginX, 0, 400),
    marginY: int(source.marginY, DEFAULTS.marginY, 0, 400),
    cardWidth: int(source.cardWidth, DEFAULTS.cardWidth, 180, 520),
    spacing: int(source.spacing, DEFAULTS.spacing, 0, 48),
    columns: int(source.columns, DEFAULTS.columns, 1, 4),
    opacity: real(source.opacity, DEFAULTS.opacity, 0.2, 1),
    compact: bool(source.compact, DEFAULTS.compact),
    // The floor is 500ms deliberately. Every sample is a handful of small
    // virtual-file reads, but a user who types 10 into the interval field should
    // not be able to turn a widget into a busy loop inside the shell process.
    intervalMs: int(source.intervalMs, DEFAULTS.intervalMs, 500, 60000),
    cards: cardList(source.cards),
    monitor: monitorName(source.monitor),
    hidePodsWhenAbsent: bool(source.hidePodsWhenAbsent, DEFAULTS.hidePodsWhenAbsent),
    showCoreBars: bool(source.showCoreBars, DEFAULTS.showCoreBars)
  }
}

// The service entry point is handed no settings of its own, so it finds its bar
// layout entry and reads the inline values from there. This is the same object
// the bar widget receives, which keeps one source of truth for both surfaces.
function fromBarConfig(barConfig, pluginId) {
  var id = String(pluginId || "")
  var layout = barConfig && typeof barConfig === "object" && barConfig.layout
    && typeof barConfig.layout === "object" ? barConfig.layout : {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      if (entry && typeof entry === "object" && String(entry.id || "") === id) return entry
    }
  }
  return {}
}

// Which screen edges the desktop window anchors to, and how the stack aligns
// inside it. A corner window is sized to its content rather than the screen, so
// the rest of the wallpaper keeps its own click handling.
function anchorsFor(position) {
  var name = POSITIONS.indexOf(String(position)) !== -1 ? String(position) : DEFAULTS.position
  var parts = name.split("-")
  var vertical = parts[0]
  var horizontal = parts[1]
  return {
    top: vertical === "top",
    bottom: vertical === "bottom",
    left: horizontal === "left",
    right: horizontal === "right",
    centerHorizontally: horizontal === "center",
    centerVertically: vertical === "middle"
  }
}

// Which of the wanted cards are worth drawing right now. A card whose subject is
// absent is dropped rather than shown empty, so a machine with no AirPods daemon
// does not carry a permanent "nothing here" card.
//
// This lives here rather than in CardStack so a surface can size itself from the
// same answer without reading it back off the stack it is about to configure.
function visibleCards(config, hasPods) {
  var settings = config && Array.isArray(config.cards) ? config : normalize(config)
  var out = []
  for (var i = 0; i < settings.cards.length; i++) {
    var id = settings.cards[i]
    if (id === CARD_PODS && settings.hidePodsWhenAbsent && !hasPods) continue
    out.push(id)
  }
  return out
}

function cardName(id) {
  return CARD_NAMES[String(id || "")] || ""
}

if (typeof module !== "undefined") {
  module.exports = {
    CARD_SYSTEM: CARD_SYSTEM, CARD_PODS: CARD_PODS,
    CARD_BATTERY: CARD_BATTERY, CARD_POWER: CARD_POWER,
    KNOWN_CARDS: KNOWN_CARDS,
    POSITIONS: POSITIONS,
    DEFAULTS: DEFAULTS,
    normalize: normalize,
    fromBarConfig: fromBarConfig,
    anchorsFor: anchorsFor,
    cardList: cardList,
    visibleCards: visibleCards,
    cardName: cardName
  }
}
