// Pixels for the tile grid: how big a cell is, how many fit on a screen, where a
// tile is drawn, and which cell a dragged tile is nearest. Grid.js works in
// cells and never sees any of this.

var MAX_CELLS = 256

function positive(value, fallback) {
  var n = typeof value === "number" && isFinite(value) ? value : fallback
  return Math.max(0, n)
}

// A cell is a quarter of a card, less the gaps between, so a tile `perCard`
// cells wide is exactly one card wide. Its height is passed in, because it
// follows what the cards need at the theme's font size rather than the width.
//
// The cells are centred across the available width, so the sliver left over
// from a width that is not a whole number of cells is split between both sides.
function metrics(width, height, cardWidth, gap, cellHeight, perCard) {
  var g = positive(gap, 0)
  var n = Math.max(1, Math.round(positive(perCard, 4)))
  var cw = Math.max(1, (positive(cardWidth, 268) - (n - 1) * g) / n)
  var ch = Math.max(1, positive(cellHeight, 48))
  var w = positive(width, 0)
  var h = positive(height, 0)
  var cols = Math.min(MAX_CELLS, Math.floor((w + g) / (cw + g)))
  var rows = Math.min(MAX_CELLS, Math.floor((h + g) / (ch + g)))
  var used = cols > 0 ? cols * cw + (cols - 1) * g : 0
  return {
    cellWidth: cw, cellHeight: ch, gap: g, cols: cols, rows: rows,
    originX: Math.max(0, Math.floor((w - used) / 2)), originY: 0
  }
}

function rect(tile, m) {
  if (!tile || !m) return { x: 0, y: 0, width: 0, height: 0 }
  return {
    x: m.originX + tile.col * (m.cellWidth + m.gap),
    y: m.originY + tile.row * (m.cellHeight + m.gap),
    width: tile.w * m.cellWidth + Math.max(0, tile.w - 1) * m.gap,
    height: tile.h * m.cellHeight + Math.max(0, tile.h - 1) * m.gap
  }
}

// The cell whose corner is closest to a point, which is where a tile dragged
// with its top-left corner at that point should land. Not clamped: Grid.drop
// pulls it back inside the board.
function nearestCell(m, x, y) {
  return {
    col: Math.round((Number(x) - m.originX) / (m.cellWidth + m.gap)) || 0,
    row: Math.round((Number(y) - m.originY) / (m.cellHeight + m.gap)) || 0
  }
}

// The smallest cell height that lets content `contentHeight` tall fit a tile
// `rows` cells high, given the gaps it spans.
function cellHeightFor(contentHeight, rows, gap) {
  var n = Math.max(1, Math.round(positive(rows, 1)))
  return Math.ceil(Math.max(0, positive(contentHeight, 0) - (n - 1) * positive(gap, 0)) / n)
}

function contains(r, x, y) {
  return !!r && x >= r.x && y >= r.y && x < r.x + r.width && y < r.y + r.height
}

if (typeof module !== "undefined") {
  module.exports = {
    metrics: metrics, rect: rect, nearestCell: nearestCell,
    cellHeightFor: cellHeightFor, contains: contains
  }
}
