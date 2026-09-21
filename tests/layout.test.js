// Arrangement: which widgets are worth drawing, how wide each tile is, where the
// window anchors, and how the columns are packed.
var t = require("./harness.js")
var Layout = require("../model/Layout.js")
var Settings = require("../model/Settings.js")
var Pack = require("../model/Pack.js")

var defaults = Settings.normalize({})

// ---------------------------------------------------------------- visibility

t.deep(Layout.visibleCards(defaults, { hasPods: true, hasMedia: true }),
  ["system", "media", "todo", "pods", "battery", "power"],
  "everything reporting, everything drawn")
t.deep(Layout.visibleCards(defaults, { hasPods: false, hasMedia: false }),
  ["system", "todo", "battery", "power"],
  "an absent subject drops its card rather than showing it empty")
t.deep(Layout.visibleCards(defaults, Layout.defaultState()),
  ["system", "todo", "battery", "power"],
  "the to-do card has no subject to be absent, so it is always drawn")
t.deep(Layout.visibleCards(Settings.normalize({ hideMediaWhenIdle: false }), { hasMedia: false })
  .indexOf("media") !== -1, true, "unless the user asked to keep the media card")
t.deep(Layout.visibleCards(Settings.normalize({ cards: ["media"] }), { hasMedia: true }),
  ["media"], "a single wanted card is the only one drawn")

// ---------------------------------------------------------------------- tiles

// Compact draws one tile per card, not one per reading: the Performance tile is
// a wide rectangle holding CPU, memory and GPU together. Keeping tiles and cards
// one to one is also what lets one drag reorder both layouts.
t.eq(Layout.tileSpan("system"), 2, "the performance tile spans two columns")
t.eq(Layout.tileSpan("battery"), 1, "everything else is one")
t.eq(Layout.tileSpan("todo"), 1, "including the to-do tile")
t.eq(Layout.tileLabel("todo"), "TO-DO", "which has a label like the rest")
t.eq(Layout.tileSpan("nonsense"), 1, "an unknown tile is one")
t.eq(Layout.tileLabel("system"), "PERFORMANCE", "a tile has a label")
t.eq(Layout.tileLabel("nonsense"), "", "an unknown tile has none")
t.eq(Settings.normalize({ compact: true }).columns, 2,
  "compact defaults to two columns, because one column of small squares wastes the space")
t.eq(Settings.normalize({ compact: true, columns: 3 }).columns, 3, "an explicit column count wins")
t.eq(Settings.normalize({}).columns, 1, "full cards still default to one column")
t.eq(Settings.normalize({ tileRadius: 999 }).tileRadius, 64, "the tile radius is clamped")
t.eq(Settings.normalize({ tileSize: 10 }).tileSize, 88, "the tile size is clamped")

// -------------------------------------------------------------------- anchors

t.eq(Layout.anchorsFor("bottom-center").bottom, true, "bottom-center anchors to the bottom edge")
t.eq(Layout.anchorsFor("bottom-center").left, false, "and to neither side,")
t.eq(Layout.anchorsFor("bottom-center").right, false, "so layer-shell centres it horizontally")
t.eq(Layout.anchorsFor("middle-left").left, true, "middle-left anchors to the left edge")
t.eq(Layout.anchorsFor("middle-left").top, false, "and to neither top nor bottom")
t.eq(Layout.anchorsFor("nonsense").top, true, "an unknown position falls back to the default")
t.deep(Layout.POSITIONS, Settings.POSITIONS,
  "Layout and Settings agree on the position list — they are declared in both files")

// ----------------------------------------------------------------- packing

// A Grid's rows are as tall as their tallest cell, which is what left a hole
// under a short card. Packing places each item in whichever column is shortest.
var packed = Pack.pack([{ span: 1, height: 300 }, { span: 1, height: 120 },
  { span: 1, height: 140 }, { span: 1, height: 100 }], 2, 268, 10)
t.deep(packed.boxes.map(function (b) { return b.x }), [0, 278, 278, 278],
  "three short cards stack in the second column rather than waiting for the tall one")
t.deep(packed.boxes.map(function (b) { return b.y }), [0, 0, 130, 280],
  "and each starts where the one above it ended")
t.eq(packed.height, 380, "the layout is as tall as its tallest column")
t.eq(packed.width, 546, "and as wide as its columns plus the gap between them")

var spanned = Pack.pack([{ span: 2, height: 132 }, { span: 1, height: 132 },
  { span: 1, height: 132 }], 2, 132, 10)
t.eq(spanned.boxes[0].width, 274, "a two-column item is as wide as both columns and the gap")
t.deep(spanned.boxes.map(function (b) { return b.y }), [0, 142, 142],
  "and the items after it start below, on both columns")
t.eq(Pack.pack([{ span: 2, height: 100 }], 1, 132, 10).boxes[0].width, 132,
  "a two-column item in a one-column layout is simply one wide")
t.eq(Pack.pack([], 2, 132, 10).height, 0, "nothing to pack is no height")
t.eq(Pack.clampColumns(99), 6, "columns are bounded")
t.eq(Pack.clampColumns("x"), 1, "an unparseable column count is one")

t.eq(Pack.boxAt(packed.boxes, 10, 10), 0, "a point finds the box it is in")
t.eq(Pack.boxAt(packed.boxes, 300, 200), 2, "including one further down a column")
t.eq(Pack.boxAt(packed.boxes, 9999, 9999), -1, "and outside everything finds nothing")
t.deep(Pack.move(["a", "b", "c"], 0, 2), ["b", "c", "a"], "an item moves to a new position")
t.deep(Pack.move(["a", "b", "c"], 2, 0), ["c", "a", "b"], "in either direction")
t.deep(Pack.move(["a", "b", "c"], 1, 1), ["a", "b", "c"], "moving onto itself changes nothing")
t.deep(Pack.move(["a", "b", "c"], 9, 0), ["a", "b", "c"], "an index that is not there changes nothing")

// The overlay wants one row, but only as many columns as the screen can hold.
t.eq(Layout.columnsThatFit(1544, 268, 10, 6), 5,
  "six full cards do not fit a 1600px screen; five do")
t.eq(Layout.columnsThatFit(3784, 268, 10, 6), 6, "a wide screen takes the whole row")
t.eq(Layout.columnsThatFit(0, 268, 10, 6), 6,
  "a surface that has not been laid out yet falls back to one row")
t.eq(Layout.columnsThatFit(100, 268, 10, 6), 1,
  "a screen narrower than one card still draws one")
t.eq(Layout.columnsThatFit(1544, 268, 10, 2), 2, "never more columns than there are cards")

process.exit(t.report("layout"))
