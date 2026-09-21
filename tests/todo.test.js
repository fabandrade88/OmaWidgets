// The to-do list and the Pomodoro cycle.
var t = require("./harness.js")
var Todo = require("../model/Todo.js")
var List = require("../model/TodoList.js")
var Pomodoro = require("../model/Pomodoro.js")
var Settings = require("../model/Settings.js")

var NOW = 1789000000000
var HOUR = 60 * 60 * 1000

// -------------------------------------------------------------- the file

t.deep(Todo.parse("").items, [], "no file yet is an empty list")
t.deep(Todo.parse("not json").items, [], "a file that is not JSON is an empty list, not an error")
t.deep(Todo.parse("[1,2]").items, [], "a JSON array is not a to-do file")
t.deep(Todo.parse('{"items":"nope"}').items, [], "items that are not a list are ignored")

var loaded = Todo.parse(JSON.stringify({ version: 1, items: [
  { id: "a", text: "Write the thing", deadline: NOW + HOUR, done: false, createdAt: NOW },
  { id: "b", text: "", deadline: 0 },
  { text: "No id", createdAt: NOW }
] }))
t.eq(loaded.items.length, 2, "an entry with no text is dropped; one with no id is kept")
t.eq(loaded.items[0].text, "Write the thing", "text is read")
t.eq(loaded.items[0].deadline, NOW + HOUR, "so is the deadline")
t.ok(loaded.items[1].id.length > 0, "a missing id is generated rather than left blank")

// The file is written by this plugin and read back by it, but it is a file on
// disk: it can be hand-edited, and anything in it reaches a card.
t.eq(Todo.text("a\u0000b\nc"), "a b c", "control characters in a to-do become word breaks")
t.eq(Todo.text(new Array(400).join("x")).length, 200, "a very long to-do is capped")
t.eq(Todo.text(42), "", "a to-do whose text is not a string is dropped")
t.eq(Todo.timestamp(-5), 0, "a negative deadline is no deadline")
t.eq(Todo.timestamp("tomorrow"), 0, "a deadline that is not a number is no deadline")
t.eq(Todo.parse(Todo.serialize(loaded)).items.length, 2, "what is written reads back")

// ------------------------------------------------------------- urgency

function at(offset, extra) {
  var base = { id: "x", text: "t", deadline: offset === null ? 0 : NOW + offset, done: false }
  for (var k in (extra || {})) base[k] = extra[k]
  return base
}

t.eq(List.urgency(at(null), NOW), List.NONE, "no deadline, nothing to be urgent about")
t.eq(List.urgency(at(3 * 24 * HOUR), NOW), List.CALM, "days away is calm")
t.eq(List.urgency(at(6 * HOUR), NOW), List.SOON, "within a day is worth noticing")
t.eq(List.urgency(at(30 * 60 * 1000), NOW), List.URGENT, "within two hours is worth acting on")
t.eq(List.urgency(at(-HOUR), NOW), List.OVERDUE, "past its deadline is overdue")
t.eq(List.urgency(at(-HOUR, { done: true }), NOW), List.DONE,
  "a done to-do is done, however late it was")
t.eq(List.urgency(at(24 * HOUR), NOW), List.SOON, "exactly a day out is already worth noticing")
t.eq(List.urgency(null, NOW), List.NONE, "nothing is not urgent")

// The card leads with the most pressing state, and done or undated to-dos must
// never be what it leads with.
var mixed = [at(3 * 24 * HOUR), at(-HOUR, { id: "late" }), at(null), at(0, { done: true })]
t.eq(List.worstUrgency(mixed, NOW), List.OVERDUE, "the worst state wins")
t.eq(List.worstUrgency([at(null), at(0, { done: true })], NOW), List.NONE,
  "done and undated raise nothing")
t.eq(List.worstUrgency([], NOW), List.NONE, "an empty list raises nothing")
t.eq(List.worstUrgency([at(-HOUR, { archived: true })], NOW), List.NONE,
  "an archived to-do cannot make the card red")

// ------------------------------------------------------------ the list

var items = [
  { id: "a", text: "later", deadline: NOW + 3 * HOUR, done: false, createdAt: 1 },
  { id: "b", text: "sooner", deadline: NOW + HOUR, done: false, createdAt: 2 },
  { id: "c", text: "undated", deadline: 0, done: false, createdAt: 3 },
  { id: "d", text: "finished", deadline: NOW + HOUR, done: true, createdAt: 4 },
  { id: "e", text: "put away", deadline: 0, done: true, archived: true, createdAt: 5 }
]

t.deep(List.sorted(items, NOW).map(function (i) { return i.id }), ["b", "a", "c", "d"],
  "soonest first, then undated, then done — and archived is not in the list at all")
t.deep(List.counts(items, NOW), { open: 3, done: 1, total: 4, archived: 1 }, "counts add up")

t.eq(List.toggleDone(items, "a", NOW)[0].done, true, "toggling marks one done")
t.eq(List.toggleDone(items, "a", NOW)[0].doneAt, NOW, "and records when")
t.eq(List.toggleDone(List.toggleDone(items, "a", NOW), "a", NOW)[0].done, false, "and back again")
t.eq(List.toggleDone(List.toggleDone(items, "a", NOW), "a", NOW)[0].doneAt, 0,
  "clearing done clears when")
t.eq(List.toggleDone(items, "missing", NOW).length, items.length, "toggling nothing changes nothing")
t.eq(items[0].done, false, "and none of it mutates the list it was given")

t.eq(List.setArchived(items, "a", true)[0].archived, true, "archiving puts one away")
t.eq(List.archived(List.setArchived(items, "a", true)).length, 2, "where it can be found again")
t.eq(List.setArchived(items, "e", false)[4].archived, false, "and it can be brought back")
t.eq(List.remove(items, "a").length, 4, "removing drops one")
t.eq(List.archiveDone(items).filter(function (i) { return i.archived }).length, 2,
  "archiving the done ones puts away exactly those")
t.eq(List.archiveDone(items)[0].archived, undefined, "and leaves the open ones alone")

// ----------------------------------------------------------- pomodoro

t.eq(Pomodoro.durationSeconds(Pomodoro.FOCUS, {}), 25 * 60, "focus is twenty-five minutes")
t.eq(Pomodoro.durationSeconds(Pomodoro.SHORT_BREAK, {}), 5 * 60, "a short break is five")
t.eq(Pomodoro.durationSeconds(Pomodoro.LONG_BREAK, {}), 15 * 60, "a long one is fifteen")
t.eq(Pomodoro.durationSeconds(Pomodoro.FOCUS, { focusMinutes: 50 }), 50 * 60, "and all of it is editable")
// Number("") is 0, not NaN. Missed here once already, and an unset duration
// clamping to its minimum makes a focus round last one minute.
t.eq(Pomodoro.durationSeconds(Pomodoro.FOCUS, { focusMinutes: "" }), 25 * 60,
  "an empty duration falls back rather than clamping to the minimum")
t.eq(Pomodoro.durationSeconds(Pomodoro.FOCUS, { focusMinutes: null }), 25 * 60, "as does a null one")
t.eq(Pomodoro.normalize({ focusMinutes: 0 }).focusMinutes, 1, "a zero duration is clamped to one minute")
t.eq(Pomodoro.normalize({ focusMinutes: 9999 }).focusMinutes, 180, "and a huge one is bounded")

var phase = Pomodoro.FOCUS
var rounds = 0
var cycle = []
for (var i = 0; i < 8; i++) {
  if (phase === Pomodoro.FOCUS) rounds++
  phase = Pomodoro.nextPhase(phase, rounds, {})
  cycle.push(phase)
}
t.deep(cycle, ["short", "focus", "short", "focus", "short", "focus", "long", "focus"],
  "a long break arrives after the fourth focus round, not before")
t.eq(Pomodoro.nextPhase(Pomodoro.LONG_BREAK, 4, {}), Pomodoro.FOCUS, "a break always returns to focus")
t.eq(Pomodoro.nextPhase(Pomodoro.FOCUS, 2, { longBreakEvery: 2 }), Pomodoro.LONG_BREAK,
  "how often the long break comes is editable too")

t.eq(Pomodoro.formatRemaining(1500), "25:00", "the clock reads as a clock")
t.eq(Pomodoro.formatRemaining(65), "1:05", "with a padded seconds field")
t.eq(Pomodoro.formatRemaining(-5), "0:00", "and never counts below zero")
// Counting up rather than down: a ring that drains to nothing looks like a
// failure state at a glance.
t.eq(Pomodoro.progress(1500, 1500), 0, "a phase that has not started has filled nothing")
t.eq(Pomodoro.progress(0, 1500), 1, "one that has ended has filled the ring")
t.eq(Pomodoro.progress(750, 1500), 0.5, "and halfway is half")
t.eq(Pomodoro.progress(10, 0), -1, "with no duration there is no progress to show")

// Chaining the rounds is opt-in: the setting exists, defaults to off, and only
// an explicit true (or "true") turns it on.
t.eq(Settings.normalize({}).autoAdvance, false, "a phase that ends waits for you by default")
t.eq(Settings.normalize({ autoAdvance: true }).autoAdvance, true, "until it is asked to chain")
t.eq(Settings.normalize({ autoAdvance: "true" }).autoAdvance, true,
  "a hand-edited shell.json says true as a string")
t.eq(Settings.normalize({ autoAdvance: "sometimes" }).autoAdvance, false,
  "and anything else falls back to waiting")

process.exit(t.report("todo"))
