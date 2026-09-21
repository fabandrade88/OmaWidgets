// Operations on a to-do list, and how it is sorted and counted.
//
// Separate from Todo.js so the file format and the editing rules can be read
// apart from each other. Every function returns a new list rather than mutating
// one, which is what lets QML notice the change.
var CALM = "calm"
var SOON = "soon"
var URGENT = "urgent"
var OVERDUE = "overdue"
var DONE = "done"
var NONE = "none"

var SOON_MS = 24 * 60 * 60 * 1000
var URGENT_MS = 2 * 60 * 60 * 1000

function list(value) {
  return Array.isArray(value) ? value.slice() : []
}

// How close this one's deadline is, which is what colours it.
function urgency(todo, now) {
  if (!todo) return NONE
  if (todo.done === true) return DONE
  if (!(todo.deadline > 0)) return NONE
  var at = typeof now === "number" && isFinite(now) ? now : Date.now()
  var left = todo.deadline - at
  if (left <= 0) return OVERDUE
  if (left <= URGENT_MS) return URGENT
  if (left <= SOON_MS) return SOON
  return CALM
}

// The most pressing state in the list, which is what the card leads with. Done
// and undated to-dos do not raise an alarm, so they never win.
var RANK = {}
RANK[NONE] = 0
RANK[DONE] = 0
RANK[CALM] = 1
RANK[SOON] = 2
RANK[URGENT] = 3
RANK[OVERDUE] = 4

function worstUrgency(todos, now) {
  var items = list(todos)
  var worst = NONE
  for (var i = 0; i < items.length; i++) {
    if (items[i].archived === true) continue
    var level = urgency(items[i], now)
    if (RANK[level] > RANK[worst]) worst = level
  }
  return worst
}

function active(todos) {
  var items = list(todos)
  var out = []
  for (var i = 0; i < items.length; i++)
    if (items[i].archived !== true) out.push(items[i])
  return out
}

function archived(todos) {
  var items = list(todos)
  var out = []
  for (var i = 0; i < items.length; i++)
    if (items[i].archived === true) out.push(items[i])
  return out
}

// Soonest deadline first, then the undated, then the done. A list you are
// working from should open on the thing that is most nearly late.
function sorted(todos, now) {
  var items = active(todos)
  items.sort(function (a, b) {
    if (a.done !== b.done) return a.done ? 1 : -1
    var ad = a.deadline > 0 ? a.deadline : Infinity
    var bd = b.deadline > 0 ? b.deadline : Infinity
    if (ad !== bd) return ad - bd
    return (a.createdAt || 0) - (b.createdAt || 0)
  })
  return items
}

function counts(todos, now) {
  var items = active(todos)
  var open = 0
  var done = 0
  for (var i = 0; i < items.length; i++) {
    if (items[i].done === true) done++
    else open++
  }
  return { open: open, done: done, total: items.length, archived: archived(todos).length }
}

function replace(todos, id, change) {
  var items = list(todos)
  var out = []
  for (var i = 0; i < items.length; i++) {
    if (items[i].id !== id) { out.push(items[i]); continue }
    var next = {}
    for (var key in items[i]) next[key] = items[i][key]
    for (var field in change) next[field] = change[field]
    out.push(next)
  }
  return out
}

function toggleDone(todos, id, now) {
  var items = list(todos)
  for (var i = 0; i < items.length; i++) {
    if (items[i].id !== id) continue
    var done = items[i].done !== true
    return replace(items, id, { done: done, doneAt: done ? (now || Date.now()) : 0 })
  }
  return items
}

function setArchived(todos, id, value) {
  return replace(todos, id, { archived: value === true })
}

function remove(todos, id) {
  var items = list(todos)
  var out = []
  for (var i = 0; i < items.length; i++) if (items[i].id !== id) out.push(items[i])
  return out
}

// Everything already done, put away in one go.
function archiveDone(todos) {
  var items = list(todos)
  var out = []
  for (var i = 0; i < items.length; i++) {
    if (items[i].done === true && items[i].archived !== true) {
      var next = {}
      for (var key in items[i]) next[key] = items[i][key]
      next.archived = true
      out.push(next)
    } else {
      out.push(items[i])
    }
  }
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    CALM: CALM, SOON: SOON, URGENT: URGENT, OVERDUE: OVERDUE, DONE: DONE, NONE: NONE,
    SOON_MS: SOON_MS, URGENT_MS: URGENT_MS,
    urgency: urgency,
    worstUrgency: worstUrgency,
    active: active,
    archived: archived,
    sorted: sorted,
    counts: counts,
    replace: replace,
    toggleDone: toggleDone,
    setArchived: setArchived,
    remove: remove,
    archiveDone: archiveDone
  }
}
