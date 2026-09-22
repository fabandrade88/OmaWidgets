// Selecting, hiding and reordering the desktop widgets.
//
// All of it is list arithmetic over the card list, so it lives here rather than
// in the service: the rules about what a drag may and may not do to a
// hand-edited `cards` array are worth testing directly.
// Array.isArray is false for a list that came across the QML boundary as a
// sequence — it indexes and has a length, but it is not an Array — so the
// length is what decides. See Settings.asList for what that cost once.
function list(value) {
  if (Array.isArray(value)) return value.slice()
  if (!value || typeof value !== "object") return []
  var length = value.length
  if (typeof length !== "number" || !isFinite(length) || length < 0) return []
  var out = []
  for (var i = 0; i < Math.min(Math.floor(length), 256); i++) out.push(value[i])
  return out
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

// The card list is both "which widgets are on" and "what order they sit in", so
// switching one on in the popup must not disturb the order a drag established.
// Ones already on keep their place; newly chosen ones join at the end, in the
// canonical order, so turning two on at once is not arbitrary.
function applySelection(current, selected, canonical) {
  var existing = list(current)
  var wanted = list(selected)
  var order = list(canonical)
  var out = []
  for (var i = 0; i < existing.length; i++)
    if (wanted.indexOf(existing[i]) !== -1 && out.indexOf(existing[i]) === -1) out.push(existing[i])
  for (var j = 0; j < order.length; j++)
    if (wanted.indexOf(order[j]) !== -1 && out.indexOf(order[j]) === -1) out.push(order[j])
  return out
}

// One card switched on or off, keeping the order a drag established: the set is
// changed here and then reapplied, so turning a card back on returns it to
// where the user put it rather than to the end.
function toggleCard(current, card, canonical) {
  var existing = list(current)
  var chosen = existing.slice()
  var at = chosen.indexOf(card)
  if (at === -1) chosen.push(card)
  else chosen.splice(at, 1)
  return applySelection(existing, chosen, canonical)
}

// The service entry point is handed no settings of its own, so it finds its bar
// layout entry and reads the inline values from there. This is the same object
// the bar widget receives, which keeps one source of truth for both surfaces.
function fromBarConfig(barConfig, pluginId) {
  var id = String(pluginId || "")
  var layout = barConfig && typeof barConfig === "object" && barConfig.layout
    && typeof barConfig.layout === "object" ? barConfig.layout : {}
  var sections = ["left", "center", "right"]
  for (var s = 0; s < sections.length; s++) {
    var entries = layout[sections[s]]
    if (!Array.isArray(entries)) continue
    for (var i = 0; i < entries.length; i++) {
      var entry = entries[i]
      if (entry && typeof entry === "object" && String(entry.id || "") === id) return entry
    }
  }
  return {}
}

if (typeof module !== "undefined") {
  module.exports = {
    toggleSelection: toggleSelection,
    without: without,
    reorder: reorder,
    nextSelection: nextSelection,
    applySelection: applySelection,
    toggleCard: toggleCard,
    fromBarConfig: fromBarConfig,
    moveBy: moveBy
  }
}
