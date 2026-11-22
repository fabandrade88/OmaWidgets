// The tile grid: full cards placed on a board of cells instead of packed into
// columns.
//
// Every card has a fixed size in cells, and a tile's height counts the gaps it
// spans, so two short tiles stacked are exactly as tall as one tall one and the
// edges line up. Positions are kept in cells rather than pixels, so another
// screen only changes how many cells fit.
//
// Pure geometry over { col, row, w, h } rectangles. Nothing here knows about
// pixels (Cells.js does) or QML, so every rule runs under node.

// One full card is this many cells wide, which is what makes a tile exactly as
// wide as the same card in the column layout.
var CARD_COLUMNS = 4

// Performance is five tall so that each short pair beside it — battery over
// power, AirPods over now playing — ends exactly where it does.
var SIZES = {
  system: { w: CARD_COLUMNS, h: 5 },
  todo: { w: CARD_COLUMNS, h: 6 },
  pods: { w: CARD_COLUMNS, h: 3 },
  battery: { w: CARD_COLUMNS, h: 3 },
  power: { w: CARD_COLUMNS, h: 2 },
  media: { w: CARD_COLUMNS, h: 2 }
}

// Far beyond any real screen. It bounds every scan below, whatever was passed.
var MAX_CELLS = 256

function own(map, key) {
  return !!map && typeof map === "object" && Object.prototype.hasOwnProperty.call(map, key)
}

function whole(value, fallback) {
  var n = typeof value === "number" && isFinite(value) ? Math.round(value) : fallback
  return Math.max(-MAX_CELLS, Math.min(MAX_CELLS, n))
}

function count(value) {
  return Math.max(0, Math.min(MAX_CELLS, whole(value, 0)))
}

function sizeOf(id) {
  var size = own(SIZES, String(id)) ? SIZES[String(id)] : SIZES.battery
  return { w: size.w, h: size.h }
}

function isCell(c) {
  return !!c && typeof c.col === "number" && isFinite(c.col) && typeof c.row === "number" && isFinite(c.row)
}
function isTile(t) { return isCell(t) && t.w > 0 && t.h > 0 }

function overlaps(a, b) {
  return a.col < b.col + b.w && b.col < a.col + a.w
    && a.row < b.row + b.h && b.row < a.row + a.h
}

function firstHit(rect, placed) {
  for (var i = 0; i < placed.length; i++) if (overlaps(rect, placed[i])) return placed[i]
  return null
}

// A tile saved on a bigger screen is pulled back inside this one, losing only
// the cells that no longer exist.
function clampInto(col, row, size, cols, rows) {
  return {
    col: Math.max(0, Math.min(col, cols - size.w)), row: Math.max(0, Math.min(row, rows - size.h)),
    w: size.w, h: size.h
  }
}

// The first free spot, scanned a column at a time from the corner the cards are
// set to sit in, so a fresh board stacks down that edge the way the columns do.
// With no room anywhere the tile goes below everything: off the board, but
// never on top of another tile.
function firstFree(size, placed, cols, rows, corner) {
  var name = String(corner || "")
  var fromRight = name.slice(-5) === "right"
  var fromBottom = name.indexOf("bottom") === 0
  var lastCol = cols - size.w
  var lastRow = rows - size.h
  for (var c = 0; c <= lastCol; c++) {
    for (var r = 0; r <= lastRow; r++) {
      var rect = { col: fromRight ? lastCol - c : c, row: fromBottom ? lastRow - r : r, w: size.w, h: size.h }
      if (firstHit(rect, placed) === null) return rect
    }
  }
  var below = 0
  for (var i = 0; i < placed.length; i++) below = Math.max(below, placed[i].row + placed[i].h)
  return { col: fromRight ? Math.max(0, lastCol) : 0, row: below, w: size.w, h: size.h }
}

// Where every card in `ids` goes. A saved cell is kept, in list order, wherever
// it is still free; a card with none, or whose cell another tile holds now,
// takes the first free spot. The result never overlaps.
function place(ids, saved, cols, rows, corner) {
  var c = count(cols), r = count(rows)
  var list = ids && typeof ids.length === "number" ? ids : []
  var placed = []
  var out = {}
  var waiting = []
  for (var i = 0; i < Math.min(list.length, 64); i++) {
    var id = String(list[i])
    if (!own(SIZES, id) || own(out, id) || waiting.indexOf(id) !== -1) continue
    var cell = own(saved, id) ? saved[id] : null
    if (isCell(cell)) {
      var rect = clampInto(whole(cell.col, 0), whole(cell.row, 0), sizeOf(id), c, r)
      if (firstHit(rect, placed) === null) {
        placed.push(rect)
        out[id] = rect
        continue
      }
    }
    waiting.push(id)
  }
  for (var j = 0; j < waiting.length; j++) {
    var free = firstFree(sizeOf(waiting[j]), placed, c, r, corner)
    placed.push(free)
    out[waiting[j]] = free
  }
  return out
}

function inside(layout, cols, rows) {
  for (var id in layout) {
    if (!own(layout, id)) continue
    var t = layout[id]
    if (t.col < 0 || t.row < 0 || t.col + t.w > cols || t.row + t.h > rows) return false
  }
  return true
}

// The board after `id` is put down at (col, row). It takes that cell, and
// every tile it lands on is pushed straight down, as far as it must go and no
// further. Always worked out from the board as it was before the drag began,
// so a tile pushed aside slides back once the dragged one moves on.
//
// `fits` is false when a push would send a tile off the bottom of the board,
// which is a drop to refuse rather than persist.
function drop(layout, id, col, row, cols, rows) {
  var c = count(cols), r = count(rows)
  var name = String(id)
  var out = {}
  if (!own(layout, name) || !isTile(layout[name])) {
    for (var k in layout) if (own(layout, k) && isTile(layout[k])) out[k] = layout[k]
    return { layout: out, fits: false }
  }
  var moving = layout[name]
  var settled = [clampInto(whole(col, moving.col), whole(row, moving.row), moving, c, r)]
  out[name] = settled[0]

  var others = []
  for (var key in layout) if (own(layout, key) && key !== name && isTile(layout[key])) others.push(key)
  others.sort(function (a, b) {
    return (layout[a].row - layout[b].row) || (layout[a].col - layout[b].col)
  })
  for (var i = 0; i < others.length; i++) {
    var t = layout[others[i]]
    var rect = { col: t.col, row: t.row, w: t.w, h: t.h }
    var hit
    // Each pass moves the tile strictly lower, and the settled tiles end
    // somewhere, so this stops.
    while ((hit = firstHit(rect, settled)) !== null) rect.row = hit.row + hit.h
    settled.push(rect)
    out[others[i]] = rect
  }
  return { layout: out, fits: inside(out, c, r) }
}

// One cell in any direction, which is the keyboard's way of dragging. Null when
// the tile is not on the board or is already against that edge.
function nudge(layout, id, dc, dr, cols, rows) {
  var name = String(id)
  if (!own(layout, name) || !isTile(layout[name])) return null
  var tile = layout[name]
  var step = function (d) { return d > 0 ? 1 : (d < 0 ? -1 : 0) }
  var result = drop(layout, name, tile.col + step(dc), tile.row + step(dr), cols, rows)
  var moved = result.layout[name]
  return moved.col === tile.col && moved.row === tile.row ? null : result
}

// What to persist: every placed tile's cell, and the remembered cell of any
// card not on screen right now, so a widget hidden for a while comes back
// where it was.
function toSaved(layout, previous) {
  var out = {}
  for (var id in SIZES) {
    var from = own(layout, id) && isCell(layout[id]) ? layout[id] : (own(previous, id) ? previous[id] : null)
    if (isCell(from)) out[id] = { col: Math.round(from.col), row: Math.round(from.row) }
  }
  return out
}

if (typeof module !== "undefined") {
  module.exports = {
    CARD_COLUMNS: CARD_COLUMNS, SIZES: SIZES, MAX_CELLS: MAX_CELLS,
    sizeOf: sizeOf, overlaps: overlaps, place: place, drop: drop,
    inside: inside, nudge: nudge, toSaved: toSaved
  }
}
