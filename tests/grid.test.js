// The tile grid: placing cards on cells, pushing them out of the way, the
// pixels behind it, and what a hand-edited `tiles` setting may contain.
var t = require("./harness.js")
var Grid = require("../model/Grid.js")
var Cells = require("../model/Cells.js")
var Layout = require("../model/Layout.js")
var Settings = require("../model/Settings.js")

var ALL = ["system", "media", "todo", "pods", "battery", "power"]

function noOverlap(layout) {
  var ids = Object.keys(layout)
  for (var i = 0; i < ids.length; i++)
    for (var j = i + 1; j < ids.length; j++)
      if (Grid.overlaps(layout[ids[i]], layout[ids[j]])) return false
  return true
}

function at(layout, id) { return layout[id].col + "," + layout[id].row }

// --------------------------------------------------------------------- sizes

t.eq(Grid.sizeOf("system").h, 5, "performance is five cells tall")
t.eq(Grid.sizeOf("todo").h, 6, "the to-do tile is six")
t.eq(Grid.sizeOf("battery").h + Grid.sizeOf("power").h, Grid.sizeOf("system").h,
  "battery over power is as tall as performance")
t.eq(Grid.sizeOf("pods").h + Grid.sizeOf("media").h, Grid.sizeOf("system").h,
  "and so is AirPods over now playing")
t.eq(Grid.sizeOf("nonsense").w, Grid.CARD_COLUMNS, "an unknown id still gets a size")

// ------------------------------------------------------------------- placing

var fresh = Grid.place(ALL, {}, 30, 16, "top-right")
t.ok(noOverlap(fresh), "a fresh board never overlaps")
t.eq(at(fresh, "system"), "26,0", "the first card takes the top-right corner")
t.eq(at(fresh, "media"), "26,5", "the next stacks under it, down the same edge")
t.eq(at(fresh, "todo"), "26,7", "and the next")
t.eq(at(fresh, "pods"), "26,13", "for as long as the edge has room")
t.eq(at(fresh, "battery"), "22,0", "then the next column inward starts at the top")
t.eq(at(Grid.place(["system"], {}, 30, 16, "top-left"), "system"), "0,0", "top-left starts at the left")
t.eq(at(Grid.place(["system"], {}, 30, 16, "bottom-right"), "system"), "26,11", "bottom starts at the bottom")

var saved = { system: { col: 10, row: 3 }, battery: { col: 0, row: 0 } }
var kept = Grid.place(ALL, saved, 30, 16, "top-right")
t.eq(at(kept, "system"), "10,3", "a saved cell is honoured")
t.eq(at(kept, "battery"), "0,0", "every saved cell is")
t.ok(noOverlap(kept), "alongside tiles placed fresh")

var clash = Grid.place(["system", "pods"], { system: { col: 0, row: 0 }, pods: { col: 2, row: 2 } }, 30, 16, "top-left")
t.eq(at(clash, "system"), "0,0", "the first card in the list keeps a contested spot")
t.ok(noOverlap(clash), "and the other moves to a free one")

var small = Grid.place(["system"], { system: { col: 40, row: 40 } }, 20, 10, "top-left")
t.eq(at(small, "system"), "16,5", "a tile saved on a bigger screen is pulled back inside")

var crowded = Grid.place(ALL, {}, 4, 8, "top-left")
t.ok(noOverlap(crowded), "a board too small for everything still never overlaps")
t.ok(!Grid.inside(crowded, 4, 8), "and says the extra tiles fell off it")

t.eq(Object.keys(Grid.place(["todo", "todo", "todo"], {}, 30, 16, "top-left")).length, 1,
  "a duplicate id is placed once")
t.deep(Grid.place(null, null, NaN, -4, null), {}, "nonsense in, an empty board out")
t.eq(Object.getPrototypeOf(Grid.place(["__proto__", "constructor"], {}, 30, 16)), Object.prototype,
  "an id that is not a card is never placed, so it cannot reach the result's prototype")
t.ok(noOverlap(Grid.place(ALL, { system: { col: "x", row: {} } }, 30, 16)), "a malformed cell is ignored")

// ------------------------------------------------------------------ dropping

var board = Grid.place(["system", "battery", "power"], {
  system: { col: 0, row: 0 }, battery: { col: 4, row: 0 }, power: { col: 4, row: 3 }
}, 30, 16, "top-left")

var onto = Grid.drop(board, "system", 4, 1, 30, 16)
t.eq(at(onto.layout, "system"), "4,1", "the dropped tile takes the cell it was dropped on")
t.eq(at(onto.layout, "battery"), "4,6", "a tile it lands on is pushed straight down")
t.eq(at(onto.layout, "power"), "4,9", "and the one under that is pushed along with it")
t.ok(onto.fits && noOverlap(onto.layout), "with nothing overlapping")

var away = Grid.drop(board, "system", 12, 0, 30, 16)
t.eq(at(away.layout, "battery"), "4,0", "moving on from a drop lets the tiles slide back")
t.eq(at(Grid.drop(board, "system", -9, -9, 30, 16).layout, "system"), "0,0",
  "a drop past the edge is pulled back inside")
t.eq(at(Grid.drop(board, "battery", 20, 7, 30, 16).layout, "battery"), "20,7",
  "empty cells stay empty: a tile may be put down anywhere free")

var off = Grid.drop(board, "system", 4, 2, 30, 10)
t.ok(!off.fits, "a push off the bottom of the board is reported, to be refused")
t.ok(!Grid.drop(board, "nonsense", 1, 1, 30, 16).fits, "an unknown tile cannot be dropped")

// ----------------------------------------------------------------- the keys

t.eq(at(Grid.nudge(board, "power", 1, 0, 30, 16).layout, "power"), "5,3", "a nudge moves one cell")
t.eq(Grid.nudge(board, "system", -1, 0, 30, 16), null, "against the edge it does nothing")
t.eq(Grid.nudge(board, "missing", 1, 0, 30, 16), null, "and a tile not on the board is not moved")
t.eq(at(Grid.nudge(board, "power", 0, -1, 30, 16).layout, "battery"), "4,4",
  "nudging onto a tile pushes it down, the same as a drop")

t.eq(Grid.drop({ system: null }, "system", 0, 0, 20, 20).fits, false, "a malformed tile is refused, not read")
t.deep(Object.keys(Grid.drop({ system: { col: 0, row: 0, w: 4, h: 5 }, todo: "x" }, "system", 1, 1, 20, 20).layout),
  ["system"], "and a malformed neighbour is dropped rather than pushed")

// ----------------------------------------------------------------- persisting

var persisted = Grid.toSaved({ system: { col: 2, row: 3, w: 4, h: 4 } },
  { media: { col: 9, row: 9 }, system: { col: 0, row: 0 } })
t.deep(persisted, { system: { col: 2, row: 3 }, media: { col: 9, row: 9 } },
  "a hidden card keeps its remembered cell; a placed one is updated")
t.deep(Grid.toSaved({}, { system: { col: NaN, row: 1 }, todo: "x", media: { col: 2, row: 3 } }),
  { media: { col: 2, row: 3 } }, "nothing but whole cells is ever persisted")

// -------------------------------------------------- random boards and drops

var seed = 7
function rand(n) { seed = (seed * 1103515245 + 12345) % 2147483648; return seed % n }
var clean = true
for (var round = 0; round < 400; round++) {
  var cols = 4 + rand(30)
  var rows = 6 + rand(20)
  var cells = {}
  for (var c = 0; c < ALL.length; c++) if (rand(3)) cells[ALL[c]] = { col: rand(40) - 5, row: rand(30) - 5 }
  var layout = Grid.place(ALL, cells, cols, rows, Layout.POSITIONS[rand(8)])
  if (!noOverlap(layout)) clean = false
  var moved = Grid.drop(layout, ALL[rand(ALL.length)], rand(cols + 4) - 2, rand(rows + 4) - 2, cols, rows)
  if (!noOverlap(moved.layout) || Object.keys(moved.layout).length !== ALL.length) clean = false
}
t.ok(clean, "400 random boards and drops: no tile ever overlaps another, and none is lost")

// --------------------------------------------------------------------- pixels

var m = Cells.metrics(1920, 1000, 268, 10, 48, Grid.CARD_COLUMNS)
t.eq(Cells.rect({ col: 0, row: 0, w: 4, h: 4 }, m).width, 268, "a tile four cells wide is one card wide")
t.eq(Cells.rect({ col: 0, row: 0, w: 4, h: 4 }, m).height,
  2 * Cells.rect({ col: 0, row: 0, w: 4, h: 2 }, m).height + m.gap,
  "two two-cell tiles and the gap between them are exactly one four-cell tile")
t.eq(m.cols, 27, "as many cells across as fit")
t.eq(m.rows, 17, "and down")
t.ok(m.originX >= 0 && m.originX < m.cellWidth, "the leftover sliver is split, not stacked on one side")
t.deep(Cells.nearestCell(m, Cells.rect({ col: 5, row: 3, w: 4, h: 2 }, m).x + 20,
  Cells.rect({ col: 5, row: 3, w: 4, h: 2 }, m).y - 20), { col: 5, row: 3 },
  "a tile dragged near a cell snaps to it")
t.eq(Cells.cellHeightFor(250, 4, 10), 55, "the cell height a tile's content needs")
t.eq(Cells.metrics(NaN, -5, "x", -1, 0, 0).cols, 0, "nonsense metrics draw nothing rather than throwing")

// ------------------------------------------------------------------- settings

t.eq(Settings.normalize({}).grid, false, "the grid is off by default")
t.ok(Layout.usesGrid(Settings.normalize({ grid: true })), "on when asked for")
t.ok(!Layout.usesGrid(Settings.normalize({ grid: true, compact: true })), "and compact mode wins over it")
t.deep(Settings.normalize({}).tiles, {}, "no tiles saved by default")
t.deep(Settings.tileCells({ system: { col: "3", row: 2.4 }, media: "x", power: { col: 1 } }),
  { system: { col: 3, row: 2 } }, "whole cells only, for known cards, with both coordinates")
t.deep(Settings.tileCells({ todo: { col: 1e9, row: -7 } }), { todo: { col: 255, row: 0 } },
  "a cell is bounded either way")
var hostile = JSON.parse('{"__proto__": {"col": 1, "row": 1}, "constructor": {"col": 2, "row": 2}}')
t.deep(Settings.tileCells(hostile), {}, "keys that are not cards are never read")
t.deep(Settings.tileCells([1, 2, 3]), {}, "a list is not a board")
t.deep(Settings.tileCells(null), {}, "nor is null")

process.exit(t.report("grid"))
