// Column packing for the desktop layouts.
//
// Both layouts pack the same way: each item goes to whichever column is
// currently shortest, which is what keeps a short card from leaving a hole under
// it the way a Grid's uniform row heights do. Items may span more than one
// column — the compact Performance tile is a wide rectangle — so a span-2 item
// looks for the pair of adjacent columns whose taller side is lowest.
//
// Pure geometry: it is handed heights and hands back positions, so the whole
// arrangement can be exercised without a compositor.
var MAX_COLUMNS = 6

function clampColumns(value) {
  var n = typeof value === "number" && isFinite(value) ? Math.round(value) : 1
  return Math.max(1, Math.min(MAX_COLUMNS, n))
}

function spanOf(item, columns) {
  var span = item && typeof item.span === "number" && isFinite(item.span)
    ? Math.round(item.span) : 1
  // A two-wide item in a one-column layout is simply one wide.
  return Math.max(1, Math.min(columns, span))
}

// Highest of the column tops this item would sit on.
function shelfFor(tops, start, span) {
  var y = 0
  for (var i = start; i < start + span; i++) y = Math.max(y, tops[i])
  return y
}

// Leftmost on a tie, so the order stays stable and predictable rather than
// shuffling between equally good positions on every relayout.
function bestStart(tops, columns, span) {
  var best = 0
  var bestShelf = shelfFor(tops, 0, span)
  for (var start = 1; start <= columns - span; start++) {
    var shelf = shelfFor(tops, start, span)
    if (shelf < bestShelf - 0.5) {
      best = start
      bestShelf = shelf
    }
  }
  return best
}

// items: [{ span, height }] in the order they should be placed.
// Returns { boxes: [{ x, y, width, height }], width, height }.
function pack(items, columns, columnWidth, spacing) {
  var list = Array.isArray(items) ? items : []
  var count = clampColumns(columns)
  var unit = typeof columnWidth === "number" && columnWidth > 0 ? columnWidth : 0
  var gap = typeof spacing === "number" && spacing >= 0 ? spacing : 0

  var tops = []
  for (var c = 0; c < count; c++) tops.push(0)

  var boxes = []
  for (var i = 0; i < list.length; i++) {
    var span = spanOf(list[i], count)
    var start = bestStart(tops, count, span)
    var y = shelfFor(tops, start, span)
    var height = list[i] && typeof list[i].height === "number" && isFinite(list[i].height)
      ? Math.max(0, list[i].height) : 0

    boxes.push({
      x: start * (unit + gap),
      y: y,
      width: span * unit + (span - 1) * gap,
      height: height
    })
    for (var f = start; f < start + span; f++) tops[f] = y + height + gap
  }

  var tallest = 0
  for (var t = 0; t < count; t++) tallest = Math.max(tallest, tops[t])

  return {
    boxes: boxes,
    width: count * unit + Math.max(0, count - 1) * gap,
    height: Math.max(0, tallest - gap)
  }
}

// Which packed box the point falls in, or -1. Used to decide where a dragged
// item should land.
function boxAt(boxes, x, y) {
  var list = Array.isArray(boxes) ? boxes : []
  for (var i = 0; i < list.length; i++) {
    var b = list[i]
    if (x >= b.x && x < b.x + b.width && y >= b.y && y < b.y + b.height) return i
  }
  return -1
}

// Moves one entry of an array to another position, returning a new array.
function move(list, from, to) {
  var source = Array.isArray(list) ? list.slice() : []
  if (from < 0 || from >= source.length) return source
  var target = Math.max(0, Math.min(source.length - 1, to))
  if (target === from) return source
  var item = source.splice(from, 1)[0]
  source.splice(target, 0, item)
  return source
}

if (typeof module !== "undefined") {
  module.exports = {
    MAX_COLUMNS: MAX_COLUMNS,
    clampColumns: clampColumns,
    spanOf: spanOf,
    pack: pack,
    boxAt: boxAt,
    move: move
  }
}
