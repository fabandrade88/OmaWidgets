// To-dos: the list, its file format, and how close a deadline is.
//
// The list lives in a file this plugin writes, so both directions matter — what
// is read back may have been edited by hand or written by an older version, and
// what is written has to stay readable by the next one. Every field is checked
// on the way in and normalised on the way out.
var VERSION = 1
var MAX_TEXT = 200
var MAX_ITEMS = 500

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

function text(raw, cap) {
  if (typeof raw !== "string") return ""
  return raw.replace(/[\u0000-\u001F\u007F]/g, " ").replace(/\s+/g, " ").trim()
    .slice(0, cap || MAX_TEXT)
}

// Milliseconds since the epoch, or 0 for "no deadline". Stored as a number so
// the file does not depend on anyone's timezone rules to compare two dates.
function timestamp(raw) {
  if (typeof raw !== "number" || !isFinite(raw) || raw <= 0) return 0
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
  var body = String(raw || "").trim()
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
    VERSION: VERSION, MAX_TEXT: MAX_TEXT, MAX_ITEMS: MAX_ITEMS,
    CALM: CALM, SOON: SOON, URGENT: URGENT, OVERDUE: OVERDUE, DONE: DONE, NONE: NONE,
    SOON_MS: SOON_MS, URGENT_MS: URGENT_MS,
    text: text,
    timestamp: timestamp,
    empty: empty,
    parse: parse,
    serialize: serialize
  }
}
