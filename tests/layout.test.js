// Arrangement and media selection: which cards are worth drawing, what they
// become in compact mode, where the window anchors, and which player a card
// should follow.
var t = require("./harness.js")
var Layout = require("../model/Layout.js")
var Media = require("../model/Media.js")
var Settings = require("../model/Settings.js")
var Pack = require("../model/Pack.js")
var Arrange = require("../model/Arrange.js")

var defaults = Settings.normalize({})

// ---------------------------------------------------------------- visibility

t.deep(Layout.visibleCards(defaults, { hasPods: true, hasMedia: true }),
  ["system", "media", "pods", "battery", "power"], "everything reporting, everything drawn")
t.deep(Layout.visibleCards(defaults, { hasPods: false, hasMedia: false }),
  ["system", "battery", "power"], "an absent subject drops its card rather than showing it empty")
t.deep(Layout.visibleCards(defaults, Layout.defaultState()),
  ["system", "battery", "power"], "the default state reports nothing present")
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

// ---------------------------------------------------------------------- media

var brave = { identity: "Brave", dbusName: "org.mpris.MediaPlayer2.brave", isPlaying: false,
  trackTitle: "", trackArtist: "" }
var spotifyIdle = { identity: "Spotify", dbusName: "org.mpris.MediaPlayer2.spotify",
  isPlaying: false, trackTitle: "", trackArtist: "" }
var spotifyPlaying = { identity: "Spotify", dbusName: "org.mpris.MediaPlayer2.spotify",
  isPlaying: true, trackTitle: "Weightless", trackArtist: "Marconi Union", canControl: true,
  canGoNext: true, canGoPrevious: true, length: 480, position: 120,
  trackArtUrl: "https://i.scdn.co/image/abc" }
var vlcPaused = { identity: "VLC media player", isPlaying: false, trackTitle: "Interview",
  canControl: true }

t.eq(Media.pickPlayer([], ""), null, "no players, no pick")
t.eq(Media.pickPlayer([brave, spotifyIdle], ""), null,
  "players that are merely running are not something to show")
t.eq(Media.pickPlayer([brave, spotifyPlaying], ""), spotifyPlaying, "the one that is playing wins")
t.eq(Media.pickPlayer([vlcPaused, spotifyPlaying], ""), spotifyPlaying,
  "playing beats paused-with-a-track")
t.eq(Media.pickPlayer([vlcPaused], ""), vlcPaused, "a paused track is still worth showing")
t.eq(Media.pickPlayer([spotifyPlaying, vlcPaused], "vlc"), vlcPaused,
  "a named player wins over one that merely happens to be playing")
t.eq(Media.pickPlayer([spotifyPlaying], "vlc"), spotifyPlaying,
  "a named player that is not running does not suppress the rest")
t.eq(Media.matchesPreferred(spotifyPlaying, "SPOTIFY"), true, "the name match ignores case")
t.eq(Media.matchesPreferred(spotifyPlaying, ""), false, "an empty preference matches nothing")

// Quickshell hands over a QML list, which is indexable and has a length but is
// not a JavaScript Array. Guarding with Array.isArray silently produced an empty
// list, and the card said "no track" while a player sat there with a title.
function qmlList(items) {
  var fake = { length: items.length }
  for (var i = 0; i < items.length; i++) fake[i] = items[i]
  return fake
}
t.eq(Array.isArray(qmlList([spotifyPlaying])), false, "a QML list is not an Array")
t.eq(Media.pickPlayer(qmlList([brave, spotifyPlaying]), ""), spotifyPlaying,
  "and it is still picked from correctly")
t.eq(Media.toArray(qmlList([brave, spotifyPlaying])).length, 2, "an array-like is copied")
t.deep(Media.toArray(null), [], "null is an empty list")
t.deep(Media.toArray(undefined), [], "so is undefined")
t.deep(Media.toArray([brave]).length, 1, "a real array passes through")

var track = Media.describe(spotifyPlaying)
t.eq(track.title, "Weightless", "the title is read")
t.eq(track.progress, 0.25, "progress is position over length")
t.eq(track.canGoNext, true, "a capability the player reports is offered")
t.eq(Media.describe(vlcPaused).canGoNext, false, "one it does not report is not")
t.eq(Media.describe({ canGoNext: true, canControl: false }).canGoNext, false,
  "a player that cannot be controlled offers nothing, whatever else it claims")
t.eq(Media.describe(null).present, false, "no player, no track")
t.eq(Media.progressFraction(10, 0), Media.UNKNOWN, "a stream with no length has no progress")

// Titles come from whatever the player was handed, so they are foreign text.
// Control characters become a space and then collapse, rather than being
// deleted: a title with an embedded newline is two words, not one run-on.
t.eq(Media.cleanText("a\u0000b\nc\u001bd"), "a b c d",
  "control characters in a title become word breaks")
t.eq(Media.cleanText("Song\u0000\u0000Title"), "Song Title",
  "a run of them collapses to one break")
t.eq(Media.cleanText("  spaced   out  "), "spaced out", "runs of whitespace collapse")
t.eq(Media.cleanText(new Array(400).join("x")).length, 120, "a very long title is capped")
t.eq(Media.cleanText(12345), "", "a title that is not a string is dropped")

// Art URLs reach an Image, so the scheme is checked rather than assumed.
t.eq(Media.artUrl("https://i.scdn.co/image/abc"), "https://i.scdn.co/image/abc", "https art passes")
t.eq(Media.artUrl("file:///tmp/cover.png"), "file:///tmp/cover.png", "local art passes")
t.eq(Media.artUrl("data:image/png;base64,AAAA"), "", "a data URI is refused")
t.eq(Media.artUrl("javascript:alert(1)"), "", "a javascript URI is refused")
t.eq(Media.artUrl(""), "", "no art, no URL")
t.eq(Media.isRemoteArt("https://i.scdn.co/image/abc"), true, "remote art is identifiable")
t.eq(Media.isRemoteArt("file:///tmp/cover.png"), false, "local art is not remote")

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

// --------------------------------------------------------------- arranging

t.eq(Arrange.toggleSelection("", "power"), "power", "tapping an unselected widget selects it")
t.eq(Arrange.toggleSelection("power", "power"), "",
  "tapping it again lets go, which is the only way to deselect without a keyboard")
t.eq(Arrange.toggleSelection("power", "media"), "media", "tapping another moves the selection")
t.eq(Arrange.toggleSelection("power", ""), "", "selecting nothing selects nothing")

t.deep(Arrange.without(["system", "media", "power"], "media"), ["system", "power"],
  "hiding drops the widget from the list")
t.deep(Arrange.without(["system"], "absent"), ["system"], "hiding one that is not there changes nothing")

// A drag only ever sees what is on screen, and a card can be enabled but hidden
// — nothing playing hides the media card. Dropping those would mean rearranging
// the desktop silently deleted a card the user had turned on.
t.deep(Arrange.reorder(["system", "media", "pods"], ["pods", "system"]),
  ["pods", "system", "media"], "a drag reorders what it saw and keeps the rest")
t.deep(Arrange.reorder(["system", "media"], ["media", "system", "ghost"]),
  ["media", "system"], "an id that is not in the list is ignored")
t.deep(Arrange.reorder(["system", "media"], ["media", "media"]), ["media", "system"],
  "a repeated id appears once")
t.deep(Arrange.reorder(["system", "media"], []), ["system", "media"],
  "a drag that asked for nothing changes nothing")

t.eq(Arrange.nextSelection(["a", "b", "c"], "", 1), "a", "stepping from nothing selects the first")
t.eq(Arrange.nextSelection(["a", "b", "c"], "", -1), "c", "and backwards selects the last")
t.eq(Arrange.nextSelection(["a", "b", "c"], "b", 1), "c", "stepping forward moves along")
t.eq(Arrange.nextSelection(["a", "b", "c"], "c", 1), "a", "and wraps at the end")
t.eq(Arrange.nextSelection(["a", "b", "c"], "a", -1), "c", "as it does at the start")
t.eq(Arrange.nextSelection([], "a", 1), "", "with nothing on screen there is nothing to select")
t.eq(Arrange.nextSelection(["a", "b"], "gone", 1), "a",
  "a selection that is no longer shown starts again from the first")

t.deep(Arrange.moveBy(["a", "b", "c"], "c", -1), ["a", "c", "b"], "a widget moves back one place")
t.deep(Arrange.moveBy(["a", "b", "c"], "a", 1), ["b", "a", "c"], "and forward one place")
// Clamped rather than wrapping: a widget nudged past the end should stop there,
// not reappear at the other side of the desktop.
t.deep(Arrange.moveBy(["a", "b", "c"], "c", 1), ["a", "b", "c"], "moving past the end stops there")
t.deep(Arrange.moveBy(["a", "b", "c"], "a", -1), ["a", "b", "c"], "as does moving past the start")
t.deep(Arrange.moveBy(["a", "b"], "gone", 1), ["a", "b"], "moving one that is not there changes nothing")

process.exit(t.report("layout"))
