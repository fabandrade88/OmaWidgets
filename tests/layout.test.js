// Arrangement and media selection: which cards are worth drawing, what they
// become in compact mode, where the window anchors, and which player a card
// should follow.
var t = require("./harness.js")
var Layout = require("../model/Layout.js")
var Media = require("../model/Media.js")
var Settings = require("../model/Settings.js")

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

// Compact mode is a different layout, not a smaller one. The Performance card
// carries three unrelated readings and becomes three tiles.
t.deep(Layout.visibleTiles(defaults, { hasPods: true, hasMedia: true }),
  ["cpu", "memory", "gpu", "media", "pods", "battery", "power"],
  "the performance card becomes three tiles, in card order")
t.deep(Layout.visibleTiles(defaults, { hasPods: false, hasMedia: false }),
  ["cpu", "memory", "gpu", "battery", "power"], "a dropped card takes its tiles with it")
t.deep(Layout.visibleTiles(Settings.normalize({ cards: ["power", "system"] }), {}),
  ["power", "cpu", "memory", "gpu"], "tiles follow the user's card order")
t.eq(Layout.tileLabel("cpu"), "CPU", "a tile has a label")
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

process.exit(t.report("layout"))
