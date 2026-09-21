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
var CARD_MEDIA = "media"
var CARD_TODO = "todo"

// Also the canonical order: a card toggled off and back on returns to its
// place here rather than to the end of the list.
var KNOWN_CARDS = [CARD_SYSTEM, CARD_MEDIA, CARD_TODO, CARD_PODS, CARD_BATTERY, CARD_POWER]

// Kept in step with Layout.POSITIONS by tests/input.test.js. Duplicated rather
// than imported because a QML `.import` would stop `node` loading this file.
var POSITIONS = [
  "top-left", "top-center", "top-right",
  "middle-left", "middle-right",
  "bottom-left", "bottom-center", "bottom-right"
]

var CARD_NAMES = {}
CARD_NAMES[CARD_SYSTEM] = "Performance"
CARD_NAMES[CARD_PODS] = "AirPods"
CARD_NAMES[CARD_BATTERY] = "Battery"
CARD_NAMES[CARD_POWER] = "Power profile"
CARD_NAMES[CARD_MEDIA] = "Now playing"
CARD_NAMES[CARD_TODO] = "To-do"

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
  hideMediaWhenIdle: true,
  showCoreBars: true,
  // Compact mode's own geometry. A tile is square, so one number sizes it.
  tileSize: 132,
  // Rounded on purpose, and independent of Style.cornerRadius: a theme with
  // square corners still wants its small tiles rounded, which is the whole
  // visual idea of compact mode.
  tileRadius: 18,
  albumArt: true,
  preferredPlayer: "",
  // The Pomodoro cycle. 25/5/15 is a convention, not a law.
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  longBreakEvery: 4,
  todoRows: 5,
  // Day-first and 24-hour, which is what most of the world writes.
  dateFormat: "dd-MM-yyyy",
  timeFormat: "24h"
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

// Kept in step with DateTime.js by tests/datetime.test.js.
var DATE_FORMATS = ["dd-MM-yyyy", "dd/MM/yyyy", "yyyy-MM-dd", "MM/dd/yyyy"]
var TIME_FORMATS = ["24h", "12h"]

function choice(value, allowed, fallback) {
  var name = String(value === undefined || value === null ? "" : value).trim()
  return allowed.indexOf(name) !== -1 ? name : fallback
}

function normalize(raw) {
  var source = raw && typeof raw === "object" ? raw : {}
  var position = String(source.position || "").trim()
  var compact = bool(source.compact, DEFAULTS.compact)
  return {
    desktop: bool(source.desktop, DEFAULTS.desktop),
    position: POSITIONS.indexOf(position) !== -1 ? position : DEFAULTS.position,
    marginX: int(source.marginX, DEFAULTS.marginX, 0, 400),
    marginY: int(source.marginY, DEFAULTS.marginY, 0, 400),
    cardWidth: int(source.cardWidth, DEFAULTS.cardWidth, 180, 520),
    spacing: int(source.spacing, DEFAULTS.spacing, 0, 48),
    // Compact tiles are small, so a single column wastes the space a full card
    // needs. The default follows the mode rather than the other way round.
    columns: int(source.columns, compact ? 2 : DEFAULTS.columns, 1, 6),
    opacity: real(source.opacity, DEFAULTS.opacity, 0.2, 1),
    compact: compact,
    // The floor is 500ms deliberately. Every sample is a handful of small
    // virtual-file reads, but a user who types 10 into the interval field should
    // not be able to turn a widget into a busy loop inside the shell process.
    intervalMs: int(source.intervalMs, DEFAULTS.intervalMs, 500, 60000),
    cards: cardList(source.cards),
    monitor: monitorName(source.monitor),
    hidePodsWhenAbsent: bool(source.hidePodsWhenAbsent, DEFAULTS.hidePodsWhenAbsent),
    hideMediaWhenIdle: bool(source.hideMediaWhenIdle, DEFAULTS.hideMediaWhenIdle),
    showCoreBars: bool(source.showCoreBars, DEFAULTS.showCoreBars),
    tileSize: int(source.tileSize, DEFAULTS.tileSize, 88, 260),
    tileRadius: int(source.tileRadius, DEFAULTS.tileRadius, 0, 64),
    albumArt: bool(source.albumArt, DEFAULTS.albumArt),
    // Matched against the player's identity, D-Bus name or desktop entry, and
    // never used as anything but a substring comparison.
    preferredPlayer: monitorName(source.preferredPlayer),
    focusMinutes: int(source.focusMinutes, DEFAULTS.focusMinutes, 1, 180),
    shortBreakMinutes: int(source.shortBreakMinutes, DEFAULTS.shortBreakMinutes, 1, 60),
    longBreakMinutes: int(source.longBreakMinutes, DEFAULTS.longBreakMinutes, 1, 120),
    longBreakEvery: int(source.longBreakEvery, DEFAULTS.longBreakEvery, 1, 12),
    todoRows: int(source.todoRows, DEFAULTS.todoRows, 1, 20),
    // Validated against the list in DateTime.js, duplicated here for the same
    // reason POSITIONS is: a QML `.import` would stop node loading this file.
    dateFormat: choice(source.dateFormat, DATE_FORMATS, DEFAULTS.dateFormat),
    timeFormat: choice(source.timeFormat, TIME_FORMATS, DEFAULTS.timeFormat)
  }
}

function cardName(id) {
  return CARD_NAMES[String(id || "")] || ""
}

if (typeof module !== "undefined") {
  module.exports = {
    CARD_SYSTEM: CARD_SYSTEM, CARD_PODS: CARD_PODS,
    CARD_BATTERY: CARD_BATTERY, CARD_POWER: CARD_POWER, CARD_MEDIA: CARD_MEDIA,
    CARD_TODO: CARD_TODO,
    KNOWN_CARDS: KNOWN_CARDS,
    POSITIONS: POSITIONS,
    DATE_FORMATS: DATE_FORMATS,
    TIME_FORMATS: TIME_FORMATS,
    DEFAULTS: DEFAULTS,
    normalize: normalize,
    cardList: cardList,
    cardName: cardName
  }
}
