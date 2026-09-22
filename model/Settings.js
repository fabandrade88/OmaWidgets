// Settings normalisation.
//
// The stored object is untrusted: JSON a user or another tool edited by hand in
// ~/.config/omarchy/shell.json. A string where a number belongs, a negative
// width, an unknown card id or a position that does not exist must each produce
// a working widget rather than a broken binding, so every field is coerced and
// clamped and anything unrecognised falls back to its default.
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
  // Independent of Style.cornerRadius on purpose: a theme with square corners
  // still wants its small tiles rounded, which is compact mode's whole idea.
  tileRadius: 18,
  albumArt: true,
  preferredPlayer: "",
  // The Pomodoro cycle. 25/5/15 is a convention, not a law.
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  longBreakEvery: 4,
  todoRows: 5,
  // A phase that ends waits for you: chaining rounds without asking is how a
  // break you did not take still counts down.
  autoAdvance: false,
  // One GET of the published manifest a day, to say whether a newer version
  // exists. Nothing is installed by it — see UpdateService.
  updateCheck: true,
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

// Number("") is 0, not NaN, so an absent field is caught before the coercion:
// otherwise every missing number clamps to its minimum, not its default.
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

// A list, whatever engine handed it over. An array injected across the QML
// boundary arrives as a sequence: it indexes and has a length, but
// `Array.isArray` says false. Reading that as "no list" replaced the saved card
// order with the defaults, and the next write persisted them. Null means it is
// genuinely not a list, which is not the same as an empty one.
function asList(value) {
  if (Array.isArray(value)) return value.slice()
  if (!value || typeof value !== "object") return null
  var length = value.length
  if (typeof length !== "number" || !isFinite(length) || length < 0) return null
  var out = []
  // Bounded: a length this large is a broken value, not a card list.
  var count = Math.min(Math.floor(length), 256)
  for (var i = 0; i < count; i++) out.push(value[i])
  return out
}

// Card order is the user's, the set is ours: unknown ids drop and duplicates
// collapse, so a hand-edited list cannot render a card twice or name one that
// does not exist.
function cardList(raw) {
  var value = asList(raw)
  if (value === null) return DEFAULTS.cards.slice()
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
    // virtual-file reads, but 10ms in the interval field should not be able to
    // turn a widget into a busy loop inside the shell process.
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
    autoAdvance: bool(source.autoAdvance, DEFAULTS.autoAdvance),
    updateCheck: bool(source.updateCheck, DEFAULTS.updateCheck),
    // Validated against the list in DateTime.js, duplicated here for the same
    // reason POSITIONS is: a QML `.import` would stop node loading this file.
    dateFormat: choice(source.dateFormat, DATE_FORMATS, DEFAULTS.dateFormat),
    timeFormat: choice(source.timeFormat, TIME_FORMATS, DEFAULTS.timeFormat)
  }
}

if (typeof module !== "undefined") {
  module.exports = {
    CARD_SYSTEM: CARD_SYSTEM, CARD_PODS: CARD_PODS,
    CARD_BATTERY: CARD_BATTERY, CARD_POWER: CARD_POWER, CARD_MEDIA: CARD_MEDIA,
    CARD_TODO: CARD_TODO,
    KNOWN_CARDS: KNOWN_CARDS, POSITIONS: POSITIONS,
    DATE_FORMATS: DATE_FORMATS, TIME_FORMATS: TIME_FORMATS,
    DEFAULTS: DEFAULTS,
    asList: asList, normalize: normalize, cardList: cardList
  }
}
