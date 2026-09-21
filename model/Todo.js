// To-dos: the list, its file format, and how close a deadline is.
//
// The list lives in a file this plugin writes, so both directions matter — what
// is read back may have been edited by hand or written by an older version, and
// what is written has to stay readable by the next one. Every field is checked
// on the way in and normalised on the way out.
var VERSION = 1
var MAX_TEXT = 200
var MAX_ITEMS = 500
// The whole file. Five hundred to-dos of two hundred characters is well under
// this; anything larger is not a to-do list, and JSON.parse on it is the
// expensive part. Refused before that rather than after.
var MAX_FILE = 512 * 1024

// How close a deadline is. Named rather than coloured here: the colours are the
// card's business, the thresholds are the model's.
var CALM = "calm"
var SOON = "soon"
var URGENT = "urgent"
var OVERDUE = "overdue"
var DONE = "done"
var NONE = "none"

// A day out is calm, within a day is worth noticing, within two hours is worth
// acting on.
var SOON_MS = 24 * 60 * 60 * 1000
var URGENT_MS = 2 * 60 * 60 * 1000

// Control characters become word breaks, and the bidirectional overrides are
// dropped outright: U+202A-202E and U+2066-2069 reorder the characters around
// them, so a to-do can be made to read as something other than what it says.
// Text this plugin shows should say what it is.
var UNSAFE_TEXT = /[\u0000-\u001F\u007F]/g
var BIDI_OVERRIDE = /[\u202A-\u202E\u2066-\u2069]/g

function text(raw, cap) {
  if (typeof raw !== "string") return ""
  return raw.replace(BIDI_OVERRIDE, "").replace(UNSAFE_TEXT, " ")
    .replace(/\s+/g, " ").trim().slice(0, cap || MAX_TEXT)
}

// Milliseconds since the epoch, or 0 for "no deadline". Stored as a number so
// the file does not depend on anyone's timezone rules to compare two dates.
//
// Bounded to dates a Date can actually represent. 1e308 is finite, survives a
// rounding, and then produces an Invalid Date whose every accessor is NaN —
// which is a wrong-looking card rather than an absent deadline.
var MAX_DEADLINE = 253402300799000

function timestamp(raw) {
  if (typeof raw !== "number" || !isFinite(raw) || raw <= 0) return 0
  if (raw > MAX_DEADLINE) return 0
  return Math.round(raw)
}

function item(raw, index) {
  var source = raw && typeof raw === "object" ? raw : {}
  var body = text(source.text)
  if (body === "") return null
  return {
    // Stable enough to key a list on, and generated here so a hand-written file
    // without ids still loads.
    id: text(source.id, 40) || ("t" + index + "-" + Math.round(Math.random() * 1e9)),
    text: body,
    deadline: timestamp(source.deadline),
    done: source.done === true,
    doneAt: timestamp(source.doneAt),
    archived: source.archived === true,
    createdAt: timestamp(source.createdAt) || Date.now()
  }
}

function empty() {
  return { version: VERSION, items: [] }
}

function parse(raw) {
  var body = String(raw || "")
  if (body.length > MAX_FILE) return empty()
  body = body.trim()
  if (body === "") return empty()
  var parsed
  try {
    parsed = JSON.parse(body)
  } catch (e) {
    return empty()
  }
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) return empty()
  var list = Array.isArray(parsed.items) ? parsed.items : []
  var items = []
  for (var i = 0; i < list.length && items.length < MAX_ITEMS; i++) {
    var next = item(list[i], i)
    if (next) items.push(next)
  }
  return { version: VERSION, items: items }
}

function serialize(state) {
  var items = state && Array.isArray(state.items) ? state.items : []
  var out = []
  for (var i = 0; i < items.length && i < MAX_ITEMS; i++) {
    var next = item(items[i], i)
    if (next) out.push(next)
  }
  return JSON.stringify({ version: VERSION, items: out }, null, 2) + "\n"
}

if (typeof module !== "undefined") {
  module.exports = {
    VERSION: VERSION, MAX_TEXT: MAX_TEXT, MAX_ITEMS: MAX_ITEMS, MAX_FILE: MAX_FILE,
    MAX_DEADLINE: MAX_DEADLINE,
    CALM: CALM, SOON: SOON, URGENT: URGENT, OVERDUE: OVERDUE, DONE: DONE, NONE: NONE,
    SOON_MS: SOON_MS, URGENT_MS: URGENT_MS,
    text: text,
    timestamp: timestamp,
    empty: empty,
    parse: parse,
    serialize: serialize
  }
}
