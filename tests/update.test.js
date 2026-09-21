// The update check: where it looks, what it accepts back, and what it concludes.
var t = require("./harness.js")
var Update = require("../model/Update.js")

// The URL is rebuilt from an allowlisted shape, never followed as written, so a
// hand-edited manifest cannot aim the check at somewhere else.
t.eq(Update.rawManifestUrl("https://github.com/fabandrade88/OmaWidgets"),
  "https://raw.githubusercontent.com/fabandrade88/OmaWidgets/HEAD/manifest.json",
  "a GitHub repository becomes a raw manifest URL")
t.eq(Update.rawManifestUrl("https://github.com/fabandrade88/OmaWidgets.git"),
  "https://raw.githubusercontent.com/fabandrade88/OmaWidgets/HEAD/manifest.json",
  "with or without the .git suffix")
t.eq(Update.rawManifestUrl("https://evil.example/fabandrade88/OmaWidgets"), "",
  "another host is not a GitHub repository")
t.eq(Update.rawManifestUrl("http://github.com/a/b"), "", "and neither is plain http")
t.eq(Update.rawManifestUrl("https://github.com/a/b/../../c"), "", "no traversal in the path")
t.eq(Update.rawManifestUrl("https://github.com/a"), "", "owner without a repository is not one")
t.eq(Update.rawManifestUrl(""), "", "and neither is nothing at all")

// The plugin id reaches a command line, so it is re-checked on the way out.
t.eq(Update.commandId("io.github.fabandrade88.omawidgets"), "io.github.fabandrade88.omawidgets",
  "a plugin id passes")
t.eq(Update.commandId("a; rm -rf ~"), "", "a command substitution is not a plugin id")
t.eq(Update.commandId("../../etc/passwd"), "", "and neither is a path")
t.eq(Update.commandId(""), "", "or an empty string")

// Versions are compared numerically, segment by segment.
t.eq(Update.compare("1.10.0", "1.9.0"), 1, "ten is above nine")
t.eq(Update.compare("1.9.0", "1.10.0"), -1, "and nine below ten")
t.eq(Update.compare("1.8.0", "1.8.0"), 0, "the same version is the same version")
t.eq(Update.compare("1.8", "1.8.0"), 0, "a missing segment counts as zero")
t.eq(Update.compare("2.0.0", "1.99.99"), 1, "a major bump beats everything under it")

// What the response is allowed to be.
t.eq(Update.versionFrom('{"version":"1.9.0"}'), "1.9.0", "a manifest yields its version")
t.eq(Update.versionFrom('{"version":"' + "9".repeat(200) + '"}'), "",
  "a version longer than a version is not one")
t.eq(Update.versionFrom('{"version":"1.0.0; rm -rf ~"}'), "",
  "and neither is one with a command in it")
t.eq(Update.versionFrom("not json at all"), "", "an unparseable body yields nothing")
t.eq(Update.versionFrom('{"nope":1}'), "", "a manifest without a version yields nothing")
t.eq(Update.versionFrom('{"version":"1.0.0"}' + " ".repeat(Update.MAX_BODY)), "",
  "a body past the ceiling is refused before it is parsed")
t.eq(Update.versionFrom(null), "", "and so is nothing")

// Silence is never reported as being up to date.
t.eq(Update.describe("1.8.0", "1.9.0").state, Update.AVAILABLE, "a newer version is available")
t.eq(Update.describe("1.8.0", "1.8.0").state, Update.CURRENT, "the same one is current")
t.eq(Update.describe("1.9.0", "1.8.0").state, Update.CURRENT,
  "and an older published version means this one is ahead, not behind")
t.eq(Update.describe("1.8.0", "").state, Update.UNKNOWN, "no answer is unknown")
t.eq(Update.describe("", "1.9.0").state, Update.UNKNOWN, "not knowing our own version is too")

var DAY = 24 * 60 * 60 * 1000
t.eq(Update.dueForCheck(0, DAY, DAY), true, "a check that never ran is due")
t.eq(Update.dueForCheck(DAY, DAY + 1000, DAY), false, "one that just ran is not")
t.eq(Update.dueForCheck(DAY, 2 * DAY, DAY), true, "a day later it is due again")
t.eq(Update.dueForCheck(2 * DAY, DAY, DAY), true,
  "a clock that went backwards checks rather than waiting for it to catch up")

process.exit(t.report("update"))
