// Fixed-length sample history for the sparkline strips.
//
// The cap matters for more than tidiness: these arrays live for the whole shell
// session, and an unbounded push on a 500ms timer is a slow memory leak inside a
// process the user never restarts. push() always returns an array of exactly
// `cap` entries, so the graph's Repeater model never changes length and Qt never
// rebuilds its delegates.
var UNKNOWN = -1

function create(cap) {
  var size = capacity(cap)
  var out = []
  for (var i = 0; i < size; i++) out.push(UNKNOWN)
  return out
}

function capacity(cap) {
  var n = typeof cap === "number" && isFinite(cap) ? Math.round(cap) : 32
  return Math.max(4, Math.min(240, n))
}

// Oldest first, newest last — the reading order of the graph.
function push(series, value, cap) {
  var size = capacity(cap)
  var source = Array.isArray(series) ? series : []
  var out = []
  var start = Math.max(0, source.length - (size - 1))
  for (var i = start; i < source.length; i++) out.push(clean(source[i]))
  while (out.length < size - 1) out.unshift(UNKNOWN)
  out.push(clean(value))
  return out
}

function clean(value) {
  if (typeof value !== "number" || !isFinite(value) || value < 0) return UNKNOWN
  return Math.max(0, Math.min(1, value))
}

// Highest known sample, used to label a graph whose scale is not 0..1.
function peak(series) {
  var source = Array.isArray(series) ? series : []
  var highest = UNKNOWN
  for (var i = 0; i < source.length; i++) {
    if (source[i] <= UNKNOWN) continue
    if (highest === UNKNOWN || source[i] > highest) highest = source[i]
  }
  return highest
}

function latest(series) {
  var source = Array.isArray(series) ? series : []
  for (var i = source.length - 1; i >= 0; i--) if (source[i] > UNKNOWN) return source[i]
  return UNKNOWN
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    create: create,
    capacity: capacity,
    push: push,
    peak: peak,
    latest: latest
  }
}
