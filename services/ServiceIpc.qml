import QtQuick
import Quickshell.Io

// The `omawidgets` IPC target, split out of Service.qml so the service reads as
// what it owns rather than as a list of remote-control verbs.
//
// Everything here is a thin call onto the service; nothing decides anything.
Item {
  id: root

  required property var service

  IpcHandler {
    target: "omawidgets"

    // Summons the overlay. `omarchy-shell shell toggle <plugin-id> '{}'` does the
    // same thing; this target exists so a Hyprland keybind can read plainly.
    function toggle(): string { return root.service.toggleOverlay() ? "ok" : "unavailable" }
    function show(): string { return root.service.shell && root.service.shell.summon(root.service.pluginId, "{}") ? "ok" : "unavailable" }
    function hide(): string { return root.service.hideOverlay() ? "ok" : "unavailable" }
    function refresh(): string { root.service.refresh(); return "ok" }

    // Arranging the desktop. Selection happens by clicking a widget; these are
    // what a keybind calls once one is selected.
    function hideSelected(): string {
      var hidden = root.service.arranger.hideSelected()
      return hidden === "" ? "nothing selected" : hidden
    }
    function selected(): string { return root.service.arranger.selectedCard }
    function deselect(): string { root.service.arranger.deselect(); return "ok" }
    function select(id: string): string { root.service.arranger.select(id); return root.service.arranger.selectedCard }
    function selectNext(): string { return root.service.arranger.selectStep(1) }
    function selectPrevious(): string { return root.service.arranger.selectStep(-1) }
    function moveSelectedForward(): string { return root.service.arranger.moveSelected(1) ? "ok" : "nothing selected" }
    function moveSelectedBack(): string { return root.service.arranger.moveSelected(-1) ? "ok" : "nothing selected" }

    // What the media card is showing, for a status line or a script.
    function nowPlaying(): string {
      if (!root.service.media.hasMedia) return root.service.media.anyPlayerRunning ? "no track" : "no player"
      var track = root.service.media.track
      return (track.isPlaying ? "playing" : "paused") + "\t" + track.title + "\t" + track.artist
    }

    function playPause(): string { root.service.media.toggle(); return "ok" }
    function nextTrack(): string { root.service.media.next(); return "ok" }
    function previousTrack(): string { root.service.media.previous(); return "ok" }

    // The to-do list and the Pomodoro clock, for a keybind or a script.
    function addTodo(text: string): string { return root.service.todos.add(text, 0) ? "ok" : "empty" }
    function todos(): string {
      var c = root.service.todos.counts
      return c.open + " open\t" + c.done + " done\t" + c.archived + " archived"
    }
    function pomodoro(): string {
      var t = root.service.todos
      return (t.running ? "running" : "paused") + "\t" + t.phase + "\t" + t.remainingLabel
    }
    function startPomodoro(): string { root.service.todos.toggleRunning(); return root.service.todos.running ? "running" : "paused" }
    function skipPhase(): string { root.service.todos.skip(); return root.service.todos.phase }
    // Starts one phase by name — focus, short or long — the way the card's
    // three buttons do. An unknown name changes nothing and says so.
    function startPhase(name: string): string {
      root.service.todos.startPhase(name)
      return root.service.todos.phase === name ? root.service.todos.phase : "unknown phase"
    }
    function testAlarm(): string { root.service.todos.alarm("focus"); return "ok" }

    // Reads the current profile, and sets it only through the allowlisted path.
    function profile(): string { return root.service.power.activeProfile }
    function setProfile(name: string): string { return root.service.setProfile(name) ? "ok" : "rejected" }
    // Wraps, like tapping the compact tile: one verb reaches every profile.
    function cycleProfile(): string { root.service.cycleProfile(1); return root.service.power.activeProfile }
  }

}
