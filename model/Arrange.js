// Selecting, hiding and reordering the desktop widgets.
//
// All of it is list arithmetic over the card list, so it lives here rather than
// in the service: the rules about what a drag may and may not do to a
// hand-edited `cards` array are worth testing directly.
function list(value) {
  return Array.isArray(value) ? value.slice() : []
}

// Tapping the selected widget again lets go of it, which is the only way to
// deselect on a surface that never takes the keyboard.
function toggleSelection(current, id) {
  var name = String(id || "")
  if (name === "") return ""
  return String(current || "") === name ? "" : name
}

function without(cards, id) {
  var name = String(id || "")
  var out = []
  var source = list(cards)
  for (var i = 0; i < source.length; i++) if (source[i] !== name) out.push(source[i])
  return out
}

// The order a drag asked for, reconciled against the list that actually exists.
//
// A drag only ever sees the widgets currently on screen, and a card can be off
// screen while still being in the list — nothing playing hides the media card,
// for instance. Dropping those would mean rearranging the desktop silently
// deleted a card the user had enabled, so anything the drag did not mention
// keeps its place at the end.
function reorder(cards, requested) {
  var existing = list(cards)
  var asked = list(requested)
  var out = []
  for (var i = 0; i < asked.length; i++) {
    var id = asked[i]
    if (existing.indexOf(id) !== -1 && out.indexOf(id) === -1) out.push(id)
  }
  for (var j = 0; j < existing.length; j++)
    if (out.indexOf(existing[j]) === -1) out.push(existing[j])
  return out
}

// The next widget in the list, so a selection can be walked without a mouse.
// Wraps, and starting from nothing selects the first.
function nextSelection(cards, current, delta) {
  var source = list(cards)
  if (source.length === 0) return ""
  var at = source.indexOf(String(current || ""))
  if (at === -1) return source[delta < 0 ? source.length - 1 : 0]
  var step = delta < 0 ? -1 : 1
  return source[(at + step + source.length) % source.length]
}

// Moves one widget earlier or later in the order, which is the keyboard
// equivalent of dragging it. Clamped rather than wrapping: a widget nudged past
// the end should stop there, not reappear at the other side of the desktop.
function moveBy(cards, id, delta) {
  var source = list(cards)
  var at = source.indexOf(String(id || ""))
  if (at === -1) return source
  var target = Math.max(0, Math.min(source.length - 1, at + (delta < 0 ? -1 : 1)))
  if (target === at) return source
  var item = source.splice(at, 1)[0]
  source.splice(target, 0, item)
  return source
}

if (typeof module !== "undefined") {
  module.exports = {
    toggleSelection: toggleSelection,
    without: without,
    reorder: reorder,
    nextSelection: nextSelection,
    moveBy: moveBy
  }
}
