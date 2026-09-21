// The Pomodoro cycle: focus, a short break, and a longer one every few rounds.
//
// The whole thing is a phase and a number of seconds remaining, so it is decided
// here and the service only counts down. Durations are settings, because 25/5/15
// is a convention rather than a law.
var FOCUS = "focus"
var SHORT_BREAK = "short"
var LONG_BREAK = "long"

var DEFAULTS = {
  focusMinutes: 25,
  shortBreakMinutes: 5,
  longBreakMinutes: 15,
  // A long break after this many focus rounds.
  longBreakEvery: 4
}

var LABELS = {}
LABELS[FOCUS] = "Focus"
LABELS[SHORT_BREAK] = "Short break"
LABELS[LONG_BREAK] = "Long break"

// Number("") is 0, not NaN, so an absent field has to be caught before the
// coercion — otherwise every unset duration clamps to its minimum and a focus
// round lasts one minute.
function minutes(value, fallback, min, max) {
  if (value === undefined || value === null) return fallback
  var text = typeof value === "number" ? value : String(value).trim()
  if (text === "") return fallback
  var n = Number(text)
  if (!isFinite(n)) return fallback
  return Math.max(min, Math.min(max, Math.round(n)))
}

// Clamped so a hand-edited shell.json cannot produce a timer that never ends or
// one that ends the instant it starts.
function normalize(raw) {
  var source = raw && typeof raw === "object" ? raw : {}
  return {
    focusMinutes: minutes(source.focusMinutes, DEFAULTS.focusMinutes, 1, 180),
    shortBreakMinutes: minutes(source.shortBreakMinutes, DEFAULTS.shortBreakMinutes, 1, 60),
    longBreakMinutes: minutes(source.longBreakMinutes, DEFAULTS.longBreakMinutes, 1, 120),
    longBreakEvery: minutes(source.longBreakEvery, DEFAULTS.longBreakEvery, 1, 12)
  }
}

function isPhase(value) {
  return value === FOCUS || value === SHORT_BREAK || value === LONG_BREAK
}

function phaseLabel(phase) {
  return LABELS[phase] || LABELS[FOCUS]
}

function durationSeconds(phase, settings) {
  var s = normalize(settings)
  if (phase === SHORT_BREAK) return s.shortBreakMinutes * 60
  if (phase === LONG_BREAK) return s.longBreakMinutes * 60
  return s.focusMinutes * 60
}

// What follows the phase that just ended. A break always returns to focus; focus
// leads to the long break on every nth completed round.
function nextPhase(phase, completedFocus, settings) {
  var s = normalize(settings)
  if (phase !== FOCUS) return FOCUS
  var rounds = typeof completedFocus === "number" && isFinite(completedFocus)
    ? Math.max(0, Math.round(completedFocus)) : 0
  return rounds > 0 && rounds % s.longBreakEvery === 0 ? LONG_BREAK : SHORT_BREAK
}

function clampRemaining(seconds, total) {
  var n = typeof seconds === "number" && isFinite(seconds) ? Math.round(seconds) : 0
  var cap = typeof total === "number" && isFinite(total) ? Math.max(0, Math.round(total)) : 0
  return Math.max(0, Math.min(cap, n))
}

// Counts up as the phase runs, so the ring fills rather than empties — a ring
// that drains to nothing looks like a failure state at a glance.
function progress(remaining, total) {
  if (!(total > 0)) return -1
  return Math.max(0, Math.min(1, (total - clampRemaining(remaining, total)) / total))
}

function formatRemaining(seconds) {
  var total = typeof seconds === "number" && isFinite(seconds) ? Math.max(0, Math.round(seconds)) : 0
  var m = Math.floor(total / 60)
  var s = total % 60
  return m + ":" + (s < 10 ? "0" : "") + s
}

if (typeof module !== "undefined") {
  module.exports = {
    FOCUS: FOCUS, SHORT_BREAK: SHORT_BREAK, LONG_BREAK: LONG_BREAK,
    DEFAULTS: DEFAULTS,
    normalize: normalize,
    isPhase: isPhase,
    phaseLabel: phaseLabel,
    durationSeconds: durationSeconds,
    nextPhase: nextPhase,
    clampRemaining: clampRemaining,
    progress: progress,
    formatRemaining: formatRemaining
  }
}
