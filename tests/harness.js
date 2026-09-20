// Minimal assert harness. The model files are plain ES5 with a CommonJS tail, so
// they load into node unchanged — the same source the shell runs.
var failures = []
var passes = 0

function ok(condition, label) {
  if (condition) { passes++; return }
  failures.push(label)
}

function eq(actual, expected, label) {
  var same = actual === expected
    || (typeof actual === "number" && typeof expected === "number"
      && isFinite(actual) && isFinite(expected) && Math.abs(actual - expected) < 1e-9)
  ok(same, label + " (expected " + JSON.stringify(expected) + ", got " + JSON.stringify(actual) + ")")
}

function deep(actual, expected, label) {
  eq(JSON.stringify(actual), JSON.stringify(expected), label)
}

function report(name) {
  if (failures.length === 0) {
    console.log("ok   " + name + " — " + passes + " assertions")
    return 0
  }
  console.log("FAIL " + name + " — " + failures.length + " of " + (passes + failures.length))
  for (var i = 0; i < failures.length; i++) console.log("     " + failures[i])
  return 1
}

module.exports = { ok: ok, eq: eq, deep: deep, report: report }
