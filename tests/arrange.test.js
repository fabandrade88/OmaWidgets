// Arranging the desktop, and choosing which player the media card follows.
var t = require("./harness.js")
var Arrange = require("../model/Arrange.js")
var Media = require("../model/Media.js")

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

// The card list is both "which widgets are on" and "what order they sit in", so
// the popup's dropdown must not disturb an order a drag established.
var canonical = ["system", "media", "pods", "battery", "power"]
t.deep(Arrange.applySelection(["power", "system"], ["power", "system"], canonical),
  ["power", "system"], "a dragged order survives reopening the dropdown")
t.deep(Arrange.applySelection(["power", "system"], ["power", "system", "media"], canonical),
  ["power", "system", "media"], "a newly chosen widget joins at the end")
t.deep(Arrange.applySelection(["power", "system"], ["system"], canonical),
  ["system"], "an unchosen one drops out")
t.deep(Arrange.applySelection([], ["battery", "media"], canonical),
  ["media", "battery"], "choosing several at once uses the canonical order, not the click order")
t.deep(Arrange.applySelection(["power"], [], canonical), [], "choosing none leaves none")

process.exit(t.report("arrange"))
