// The input-handling half of the model: everything that parses text written by
// another process, and everything that gates a value on its way to a command
// line. These are the paths where a wrong answer has consequences beyond a
// mislabelled card, so they are tested as adversarially as the plugin allows.
var t = require("./harness.js")
var Pods = require("../model/Pods.js")
var Power = require("../model/Power.js")
var Settings = require("../model/Settings.js")
var Probe = require("../model/Probe.js")

// --------------------------------------------- power profile: the only write

// Two gates, and the test asserts both. The first is the hard-coded set of names
// power-profiles-daemon defines; the second is what this machine actually
// offers. Anything else must come back as "" so no command is ever built.
var offered = ["power-saver", "balanced", "performance"]
t.eq(Power.sanitizeProfile("balanced", offered), "balanced", "an offered profile passes")
t.eq(Power.sanitizeProfile("performance", offered), "performance", "performance passes")
t.eq(Power.sanitizeProfile("turbo", offered), "", "an unknown profile is refused")
t.eq(Power.sanitizeProfile("performance", ["balanced"]), "",
  "a known profile this machine does not offer is refused")
t.eq(Power.sanitizeProfile("balanced", []), "", "with no profiles reported, nothing passes")
t.eq(Power.sanitizeProfile("", offered), "", "an empty name is refused")
t.eq(Power.sanitizeProfile(null, offered), "", "a null name is refused")
t.eq(Power.sanitizeProfile(undefined, offered), "", "an undefined name is refused")
t.eq(Power.sanitizeProfile("balanced; reboot", offered), "", "a name with a shell separator is refused")
t.eq(Power.sanitizeProfile("balanced\nperformance", offered), "", "a name with a newline is refused")
t.eq(Power.sanitizeProfile("$(id)", offered), "", "a command substitution is refused")
t.eq(Power.sanitizeProfile("`id`", offered), "", "a backtick substitution is refused")
t.eq(Power.sanitizeProfile("--help", offered), "", "an option-looking name is refused")
t.eq(Power.sanitizeProfile("-rf", offered), "", "a flag-looking name is refused")
t.eq(Power.sanitizeProfile("BALANCED", offered), "", "the comparison is case sensitive")
t.eq(Power.sanitizeProfile(" balanced ", offered), "balanced", "surrounding whitespace is trimmed")
t.eq(Power.sanitizeProfile({ toString: function () { return "balanced" } }, offered), "balanced",
  "an object that stringifies to an offered profile is still checked by value")

// The daemon's own list, as omarchy-powerprofiles-list prints it.
var listed = Power.parseProfileList("performance\t0\nbalanced\t1\npower-saver\t0\n")
t.deep(listed.profiles, ["power-saver", "balanced", "performance"],
  "profiles are ordered saver to performance whatever order they arrived in")
t.eq(listed.active, "balanced", "the active profile is the one flagged 1")
t.deep(Power.parseProfileList("balanced\t1\nturbo\t0\n").profiles, ["balanced"],
  "a profile name the plugin does not know is dropped from the list")
t.deep(Power.parseProfileList("balanced\t1\nbalanced\t0\n").profiles, ["balanced"],
  "a duplicated profile appears once")
t.deep(Power.parseProfileList("").profiles, [], "no daemon, no profiles")
t.eq(Power.parseActiveProfile('s "performance"'), "performance", "busctl output is unwrapped")
t.eq(Power.parseActiveProfile('s "turbo"'), "", "an unknown active profile is discarded")
t.eq(Power.parseActiveProfile("Failed to get property"), "", "a busctl error is not a profile")

// ------------------------------------------------ librepods: foreign JSON

var REAL = '{"case":{"available":true,"charging":false,"level":40},"connected":false,'
  + '"conversational_awareness":false,"device_name":"Fab’s AirPods Pro","is_headset":false,'
  + '"is_pro_series":true,"left":{"available":true,"charging":false,"in_ear":true,"level":58},'
  + '"lid_state":2,"model_name":"AirPods Pro 3","noise_mode":2,'
  + '"right":{"available":true,"charging":false,"in_ear":true,"level":59},"schema_version":1}'

var pods = Pods.parse(REAL)
t.eq(pods.ok, true, "a real status file parses")
t.eq(pods.left.level, 58, "the left pod level is read")
t.eq(pods.right.inEar, true, "the right pod in-ear flag is read")
t.eq(pods.caseBattery.level, 40, "the case level is read")
t.eq(pods.noiseModeName, undefined, "the parser returns data, not labels")
t.eq(Pods.noiseModeName(pods.noiseMode), "Transparency", "the noise mode maps to its name")
t.eq(Pods.lowestPodLevel(pods), 58, "the lowest pod level excludes the case")
t.eq(Pods.hasAnyBattery(pods), true, "battery readings count even while disconnected")

t.eq(Pods.parse("").daemonRunning, false, "an empty file is a daemon that is not running")
t.eq(Pods.parse("{").daemonRunning, true, "a file caught mid-write still proves the daemon runs")
t.eq(Pods.parse("{").ok, false, "a truncated file yields no readings")
t.eq(Pods.parse("[1,2,3]").ok, false, "a JSON array is not a status object")
t.eq(Pods.parse("null").ok, false, "JSON null is not a status object")
t.eq(Pods.parse('{"schema_version":99}').schemaTooNew, true, "a newer schema is refused, not guessed at")
t.eq(Pods.parse('{"schema_version":1,"left":{"available":false,"level":80,"in_ear":true}}').left.level,
  Pods.UNKNOWN, "an unavailable pod's stale level is discarded")
t.eq(Pods.parse('{"schema_version":1,"left":{"available":true,"level":900}}').left.level,
  Pods.UNKNOWN, "an out-of-range level is discarded")
t.eq(Pods.parse('{"schema_version":1,"left":{"available":true,"level":"80"}}').left.level,
  Pods.UNKNOWN, "a level that is a string is not a number")
t.eq(Pods.parse('{"schema_version":1,"noise_mode":42}').noiseMode, Pods.NOISE_UNKNOWN,
  "an unknown noise mode is unknown")
t.eq(Pods.parse('{"schema_version":1,"device_name":123}').deviceName, "",
  "a device name that is not a string is dropped")

// The device name is chosen on the phone that paired the AirPods, so it is
// attacker-influenced text that lands in a card title.
var hostile = Pods.parse('{"schema_version":1,"device_name":"a\\u0000b\\nc\\u001bd"}')
t.eq(hostile.deviceName, "abcd", "control characters are stripped from a device name")
var long = Pods.parse('{"schema_version":1,"device_name":"' + new Array(400).join("x") + '"}')
t.eq(long.deviceName.length, 64, "a very long device name is capped so it cannot stretch a card")

// ------------------------------------------------------- settings: hand-edited

var defaults = Settings.normalize({})
t.eq(defaults.position, "top-right", "an empty settings object yields the defaults")
t.eq(Settings.normalize(null).cardWidth, 268, "null settings yield the defaults")
t.eq(Settings.normalize("nonsense").intervalMs, 2000, "a non-object yields the defaults")
t.eq(Settings.normalize({ intervalMs: 10 }).intervalMs, 500,
  "a tiny interval is clamped so a widget cannot become a busy loop")
t.eq(Settings.normalize({ intervalMs: 9e9 }).intervalMs, 60000, "a huge interval is clamped")
t.eq(Settings.normalize({ intervalMs: "abc" }).intervalMs, 2000, "an unparseable interval falls back")
t.eq(Settings.normalize({ cardWidth: -50 }).cardWidth, 180, "a negative card width is clamped")
t.eq(Settings.normalize({ opacity: 4 }).opacity, 1, "opacity is clamped to one")
t.eq(Settings.normalize({ columns: 99 }).columns, 4, "columns are clamped")
t.eq(Settings.normalize({ position: "somewhere" }).position, "top-right", "an unknown position falls back")
t.eq(Settings.normalize({ desktop: "false" }).desktop, false, "a stringified boolean is honoured")
t.eq(Settings.normalize({ desktop: 0 }).desktop, true, "a nonsense boolean falls back to the default")
t.deep(Settings.normalize({ cards: ["power", "system", "bogus", "power"] }).cards,
  ["power", "system"], "unknown cards are dropped and duplicates collapse")
t.deep(Settings.normalize({ cards: "system" }).cards, Settings.DEFAULTS.cards,
  "a cards value that is not an array falls back")
t.deep(Settings.normalize({ cards: [] }).cards, [], "an explicitly empty card list is respected")
t.eq(Settings.normalize({ monitor: "eDP-1\n; rm -rf /" }).monitor, "eDP-1; rm -rf /",
  "a monitor name is stripped of newlines; it reaches a screen matcher, never a shell")
t.eq(Settings.normalize({ monitor: new Array(200).join("e") }).monitor.length, 64,
  "a monitor name is length capped")

var barConfig = { layout: { left: [{ id: "omarchy.menu" }],
  center: [], right: [{ id: "other.plugin" }, { id: "mine", position: "bottom-left" }] } }
t.eq(Settings.fromBarConfig(barConfig, "mine").position, "bottom-left",
  "settings are found on this plugin's own layout entry")
t.deep(Settings.fromBarConfig(barConfig, "absent"), {}, "a plugin with no entry has no settings")
t.deep(Settings.fromBarConfig(null, "mine"), {}, "no bar config, no settings")
t.deep(Settings.fromBarConfig({ layout: { right: "not-an-array" } }, "mine"), {},
  "a malformed layout section is skipped")

// Which cards to draw is decided in the model so a surface can size itself
// without reading it back off the stack it is configuring.
t.deep(Settings.visibleCards(Settings.normalize({}), true),
  ["system", "pods", "battery", "power"], "with AirPods reporting, every card is drawn")
t.deep(Settings.visibleCards(Settings.normalize({}), false),
  ["system", "battery", "power"], "with no AirPods reporting, the pods card is dropped")
t.deep(Settings.visibleCards(Settings.normalize({ hidePodsWhenAbsent: false }), false),
  ["system", "pods", "battery", "power"], "unless the user asked to keep it")
t.deep(Settings.visibleCards(undefined, true), ["system", "pods", "battery", "power"],
  "an undefined config yields the default cards rather than throwing")
t.deep(Settings.visibleCards(Settings.normalize({ cards: [] }), true), [],
  "no cards wanted, none drawn")

// Writing a setting merges a raw change into a normalised object and then
// normalises the result. Skipping that second pass persisted the raw value, and
// the next read replaced it with the default — so a bad input lost the user's
// setting rather than being ignored.
function write(current, changes) {
  var merged = Settings.normalize(current)
  for (var key in changes) merged[key] = changes[key]
  return Settings.normalize(merged)
}

t.eq(write({ position: "bottom-left" }, { position: "top-center" }).position, "top-center",
  "a valid change is written through")
t.eq(write({ position: "bottom-left" }, { cardWidth: 300 }).cardWidth, 300,
  "an unrelated change leaves the rest alone")
t.eq(write({ position: "bottom-left" }, { cardWidth: 9000 }).cardWidth, 520,
  "an out-of-range change is clamped before it is persisted, not after")
t.eq(write({ position: "bottom-left" }, { cards: ["system", "bogus"] }).cards.length, 1,
  "an unknown card never reaches shell.json")
t.eq(Settings.POSITIONS.indexOf("nowhere"), -1,
  "an unknown position is rejected by the setter before write() ever sees it")
t.eq(Settings.POSITIONS.length, 8, "there are eight positions, and no centre")

var anchors = Settings.anchorsFor("bottom-center")
t.eq(anchors.bottom, true, "bottom-center anchors to the bottom edge")
t.eq(anchors.left, false, "bottom-center anchors to neither side")
t.eq(anchors.right, false, "so layer-shell centres it horizontally")
t.eq(Settings.anchorsFor("middle-left").left, true, "middle-left anchors to the left edge")
t.eq(Settings.anchorsFor("middle-left").top, false, "middle-left anchors to neither top nor bottom")

// ------------------------------------------------------------ probe output

var probed = Probe.parse("cpu.cores\t6\ngpu.driver\txe\nbroken-line\ncpu.temp\t/sys/class/hwmon/hwmon6/temp1_input\n")
t.eq(probed["cpu.cores"], "6", "a key/tab/value line is read")
t.eq(probed["broken-line"], undefined, "a line without a tab is dropped")
t.eq(Probe.number(probed, "cpu.cores", 0), 6, "a numeric value is typed")
t.eq(Probe.number(probed, "absent", -1), -1, "a missing numeric value falls back")
t.eq(Probe.path(probed, "cpu.temp"), "/sys/class/hwmon/hwmon6/temp1_input", "a sysfs path passes")
t.eq(Probe.path(Probe.parse("p\t/home/user/evil"), "p"), "",
  "a path outside /sys and /proc is refused even though the probe produced it")
t.eq(Probe.path(Probe.parse("p\t/sys/../home/user/evil"), "p"), "",
  "a path with a parent reference is refused")
t.eq(Probe.path(Probe.parse("p\t"), "p"), "", "an empty path is refused")
t.eq(Probe.flag(Probe.parse("gpu.temp.shared\t1"), "gpu.temp.shared"), true, "a flag reads as true")
t.eq(Probe.flag(probed, "gpu.temp.shared"), false, "an absent flag reads as false")

process.exit(t.report("input"))
