// Parsers for the kernel's own text formats: /proc/stat, /proc/meminfo,
// /proc/loadavg and hwmon temperature nodes. Pure functions — the QML services
// read the files and hand the text here, which keeps every parsing rule in one
// place that `node` can exercise directly.
// Deliberately standalone: no `.import`, so `node` can require this file
// unchanged. The three helpers below are the only overlap with Format.js, kept
// local rather than shared because a QML `.import` would make this file
// unloadable outside the shell.
var UNKNOWN = -1
var MAX_CORES = 32

function num(raw, fallback) {
  if (typeof raw === "number") return isFinite(raw) ? raw : fallback
  var text = String(raw === undefined || raw === null ? "" : raw).trim()
  if (text === "") return fallback
  var n = Number(text)
  return isFinite(n) ? n : fallback
}

function asFraction(value) {
  var n = num(value, 0)
  return Math.max(0, Math.min(1, n))
}

// /proc/stat's per-CPU lines are cumulative jiffie counters, so a single sample
// says nothing about load. Return the raw totals and let cpuLoad() diff two of
// them; a service that has only ever seen one sample reports no load rather
// than a number invented from one reading.
function parseCpuStat(text) {
  var lines = String(text || "").split("\n")
  var overall = null
  var cores = []
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i]
    if (line.indexOf("cpu") !== 0) continue
    var fields = line.split(/\s+/)
    var label = fields[0]
    if (label !== "cpu" && !/^cpu\d+$/.test(label)) continue

    var total = 0
    var idle = 0
    // Fields after the label: user nice system idle iowait irq softirq steal...
    // idle (index 4) and iowait (index 5) are both time the CPU was not doing
    // work for anyone, which is what "not busy" has to mean here.
    for (var f = 1; f < fields.length; f++) {
      var value = num(fields[f], 0)
      total += value
      if (f === 4 || f === 5) idle += value
    }
    var sample = { total: total, idle: idle }
    if (label === "cpu") overall = sample
    else if (cores.length < MAX_CORES) cores.push(sample)
  }
  return { overall: overall, cores: cores }
}

function sampleLoad(previous, next) {
  if (!previous || !next) return UNKNOWN
  var totalDelta = next.total - previous.total
  var idleDelta = next.idle - previous.idle
  // A counter that did not advance (identical samples, or a wrap after a
  // suspend) carries no information. Saying so beats dividing by zero.
  if (!(totalDelta > 0)) return UNKNOWN
  return asFraction((totalDelta - idleDelta) / totalDelta)
}

function cpuLoad(previous, next) {
  var prev = previous || { overall: null, cores: [] }
  var cur = next || { overall: null, cores: [] }
  var cores = []
  var count = Math.min(prev.cores.length, cur.cores.length)
  for (var i = 0; i < count; i++) cores.push(sampleLoad(prev.cores[i], cur.cores[i]))
  return { overall: sampleLoad(prev.overall, cur.overall), cores: cores }
}

// /proc/meminfo, as "Key:   <value> kB". MemAvailable is the kernel's own
// estimate of what a new allocation could claim, which is the only honest
// "free" on a machine that uses spare RAM for page cache.
function parseMeminfo(text) {
  var values = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var separator = lines[i].indexOf(":")
    if (separator <= 0) continue
    var key = lines[i].substring(0, separator)
    values[key] = num(lines[i].substring(separator + 1).replace(/kB/i, ""), 0)
  }

  var total = values.MemTotal || 0
  var available = values.MemAvailable
  if (available === undefined) {
    // Pre-3.14 kernels, and some containers, omit MemAvailable. Free plus the
    // reclaimable caches is the classic approximation.
    available = (values.MemFree || 0) + (values.Cached || 0) + (values.Buffers || 0)
  }
  var swapTotal = values.SwapTotal || 0
  var swapFree = values.SwapFree || 0

  return {
    totalKib: total,
    availableKib: Math.min(available, total),
    usedKib: Math.max(0, total - Math.min(available, total)),
    fraction: total > 0 ? asFraction((total - Math.min(available, total)) / total) : UNKNOWN,
    cachedKib: values.Cached || 0,
    swapTotalKib: swapTotal,
    swapUsedKib: Math.max(0, swapTotal - swapFree),
    swapFraction: swapTotal > 0 ? asFraction((swapTotal - swapFree) / swapTotal) : UNKNOWN
  }
}

// /proc/loadavg: "0.52 0.58 0.59 2/1234 5678".
function parseLoadAvg(text) {
  var fields = String(text || "").trim().split(/\s+/)
  return {
    one: num(fields[0], UNKNOWN),
    five: num(fields[1], UNKNOWN),
    fifteen: num(fields[2], UNKNOWN)
  }
}

// A hwmon or thermal_zone node holds one integer in millidegrees. An empty
// read (the node exists but the device is asleep) is not zero degrees.
function parseTemperature(text) {
  var raw = String(text || "").trim()
  if (raw === "") return UNKNOWN
  var milli = num(raw, NaN)
  if (!isFinite(milli)) return UNKNOWN
  // Anything outside this range is a sensor reporting nonsense, not a CPU.
  if (milli < -40000 || milli > 150000) return UNKNOWN
  return milli
}

// scaling_cur_freq is in kHz.
function parseCpuFrequency(text) {
  var khz = num(String(text || "").trim(), NaN)
  if (!isFinite(khz) || khz <= 0) return UNKNOWN
  return khz / 1000
}

if (typeof module !== "undefined") {
  module.exports = {
    UNKNOWN: UNKNOWN,
    MAX_CORES: MAX_CORES,
    parseCpuStat: parseCpuStat,
    sampleLoad: sampleLoad,
    cpuLoad: cpuLoad,
    parseMeminfo: parseMeminfo,
    parseLoadAvg: parseLoadAvg,
    parseTemperature: parseTemperature,
    parseCpuFrequency: parseCpuFrequency
  }
}
