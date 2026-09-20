import QtQuick
import Quickshell.Services.Mpris
import "model/Media.js" as Media

// What is playing, from MPRIS.
//
// Quickshell's Mpris service is signal-driven, so nothing here polls — except
// the playback position, which MPRIS players do not broadcast. That one timer
// runs only while something is actually playing and a surface is showing it.
Item {
  id: root

  property bool active: false
  property string preferredPlayer: ""

  readonly property var players: Mpris.players ? Mpris.players.values : []

  // Bumped whenever anything a card reads could have changed.
  //
  // Both bindings below run JS over player objects, and QML cannot see through a
  // function call to know which of their properties were read — so neither
  // re-evaluates on its own when a title arrives. Watching only the selected
  // player is not enough either: selection itself depends on whether a player
  // has a title yet, so before the first one loads there is no selection to
  // watch. Every player gets a listener, and they all feed this counter.
  property int revision: 0

  readonly property var player: {
    revision
    return Media.pickPlayer(players, preferredPlayer)
  }

  readonly property var track: {
    revision
    return Media.describe(player)
  }

  readonly property bool hasMedia: track.present && (track.title !== "" || track.artist !== "")
  readonly property bool isPlaying: track.isPlaying
  readonly property bool anyPlayerRunning: players.length > 0

  // Every control is gated on the player saying it supports it, so a card never
  // offers a button that would do nothing.
  function next() { if (player && track.canGoNext) player.next() }
  function previous() { if (player && track.canGoPrevious) player.previous() }
  function toggle() { if (player && track.canTogglePlaying) player.togglePlaying() }
  function stop() { if (player && track.canControl) player.stop() }

  Instantiator {
    model: root.players

    delegate: QtObject {
      required property var modelData

      property Connections watcher: Connections {
        target: modelData
        ignoreUnknownSignals: true
        function onTrackTitleChanged() { root.revision++ }
        function onTrackArtistChanged() { root.revision++ }
        function onTrackAlbumChanged() { root.revision++ }
        function onTrackArtUrlChanged() { root.revision++ }
        function onIsPlayingChanged() { root.revision++ }
        function onPlaybackStateChanged() { root.revision++ }
        function onCanGoNextChanged() { root.revision++ }
        function onCanGoPreviousChanged() { root.revision++ }
        function onLengthChanged() { root.revision++ }
      }

      // A player that appears already loaded fires none of the signals above.
      Component.onCompleted: root.revision++
      Component.onDestruction: root.revision++
    }
  }

  Timer {
    // MPRIS has no position-changed signal, so a progress bar has to ask. One
    // second is enough to look live, and it only runs while there is something
    // to move and someone watching it.
    interval: 1000
    running: root.active && root.isPlaying && root.track.length > 0
    repeat: true
    onTriggered: root.revision++
  }
}
