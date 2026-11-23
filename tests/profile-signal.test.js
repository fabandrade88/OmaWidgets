// The power profile can be changed by someone else, such as the bar's battery
// menu. The daemon announces it and the widget reads the announcement from
// `gdbus monitor`, so the line is parsed like any other text from outside.
var t = require("./harness.js")
var Power = require("../model/Power.js")

var line = function (body) {
  return "/net/hadess/PowerProfiles: org.freedesktop.DBus.Properties.PropertiesChanged ('net.hadess.PowerProfiles', " + body + ", @as [])"
}

t.eq(Power.parseProfileSignal(line("{'ActiveProfile': <'power-saver'>}")), "power-saver", "a change signal names the new profile")
t.eq(Power.parseProfileSignal(line("{'PerformanceDegraded': <''>}")), "", "a signal about another property is ignored")
t.eq(Power.parseProfileSignal(line("{'ActiveProfile': <'turbo'>}")), "", "an unknown profile in a signal is discarded")
t.eq(Power.parseProfileSignal("Monitoring signals on object /net/hadess/PowerProfiles"), "", "the monitor's banner is not a profile")
t.eq(Power.parseProfileSignal(undefined), "", "no line is no profile")

process.exit(t.report("profile-signal"))
