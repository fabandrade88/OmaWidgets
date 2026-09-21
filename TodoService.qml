import QtQuick
import Quickshell
import Quickshell.Io
import "model/Pomodoro.js" as Pomodoro
import "model/Todo.js" as Todo
import "model/TodoList.js" as TodoList

// The to-do list and the Pomodoro timer.
//
// This is the one thing in the plugin that keeps state of its own, so it is the
// one thing that writes a file. It goes to $XDG_STATE_HOME/omawidgets/todos.json
// — the plugin's own directory, never shell.json, which belongs to the bar.
Item {
  id: root

  property var config: ({})
  property bool active: false

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")
  readonly property string stateDir: stateHome + "/omawidgets"
  readonly property string statePath: stateDir + "/todos.json"

  property var items: []
  property bool loaded: false

  // Rebuilt on the tick below, because urgency is a function of the clock as
  // much as of the list: a deadline goes from calm to soon without anything
  // being edited.
  property int clock: 0
  readonly property var sorted: { clock; return TodoList.sorted(items, Date.now()) }
  readonly property var counts: { clock; return TodoList.counts(items, Date.now()) }
  readonly property string worstUrgency: { clock; return TodoList.worstUrgency(items, Date.now()) }
  readonly property var archivedItems: TodoList.archived(items)

  // ------------------------------------------------------------- pomodoro

  readonly property var timing: Pomodoro.normalize(config)
  property string phase: Pomodoro.FOCUS
  property int remaining: Pomodoro.durationSeconds(Pomodoro.FOCUS, timing)
  property bool running: false
  property int completedFocus: 0

  readonly property int phaseSeconds: Pomodoro.durationSeconds(phase, timing)
  readonly property real phaseProgress: Pomodoro.progress(remaining, phaseSeconds)
  readonly property string remainingLabel: Pomodoro.formatRemaining(remaining)
  readonly property string phaseLabel: Pomodoro.phaseLabel(phase)

  signal phaseEnded(string endedPhase, string nextPhase)

  function start() { if (remaining > 0) running = true }
  function pause() { running = false }
  function toggleRunning() { running ? pause() : start() }

  function resetPhase() {
    running = false
    remaining = phaseSeconds
  }

  function setPhase(next) {
    phase = Pomodoro.isPhase(next) ? next : Pomodoro.FOCUS
    remaining = phaseSeconds
  }

  // Ends the phase and moves to the next one, which is what both the skip
  // button and the countdown reaching zero do.
  function advance(announce) {
    var ended = phase
    if (ended === Pomodoro.FOCUS) completedFocus += 1
    var next = Pomodoro.nextPhase(ended, completedFocus, timing)
    setPhase(next)
    // A break that starts by itself should run by itself; one you skipped into
    // should wait for you.
    running = announce === true
    if (announce === true) {
      phaseEnded(ended, next)
      alarm(ended)
    }
  }

  function skip() { advance(false) }

  // The alarm: a sound and a notification, both fire-and-forget. Argument
  // vectors, never a shell string, so the phase name cannot become a command.
  function alarm(endedPhase) {
    var label = Pomodoro.phaseLabel(endedPhase)
    var body = endedPhase === Pomodoro.FOCUS
      ? "Focus round done. Time for a break."
      : "Break over. Back to it."
    notifyProcess.command = ["notify-send", "--app-name=OmaWidgets",
      "--icon=alarm-symbolic", label + " finished", body]
    notifyProcess.running = true
    if (!soundProcess.running) soundProcess.running = true
  }

  // ----------------------------------------------------------------- list

  function add(bodyText, deadline) {
    var body = Todo.text(bodyText)
    if (body === "") return false
    var next = items.slice()
    next.push({
      id: "t" + Date.now() + "-" + Math.round(Math.random() * 1e6),
      text: body,
      deadline: Todo.timestamp(deadline),
      done: false,
      doneAt: 0,
      archived: false,
      createdAt: Date.now()
    })
    commit(next)
    return true
  }

  function toggle(id) { commit(TodoList.toggleDone(items, id, Date.now())) }
  function archive(id) { commit(TodoList.setArchived(items, id, true)) }
  function unarchive(id) { commit(TodoList.setArchived(items, id, false)) }
  function remove(id) { commit(TodoList.remove(items, id)) }
  function archiveDone() { commit(TodoList.archiveDone(items)) }

  function commit(next) {
    items = next
    save()
  }

  function save() {
    if (!loaded) return
    stateFile.setText(Todo.serialize({ items: root.items }))
  }

  Timer {
    // One second while the timer runs, so the clock is a clock. A minute
    // otherwise, which is enough to move a deadline from calm to soon — there is
    // nothing else on this card that changes faster.
    interval: root.running ? 1000 : 60000
    running: true
    repeat: true
    onTriggered: {
      root.clock++
      if (!root.running) return
      if (root.remaining > 1) {
        root.remaining -= 1
        return
      }
      root.remaining = 0
      root.advance(true)
    }
  }

  Process {
    id: soundProcess
    // The freedesktop sound theme ships with every desktop; if it is missing the
    // notification still arrives and only the sound is lost.
    command: ["pw-play", "/usr/share/sounds/freedesktop/stereo/complete.oga"]
  }

  Process { id: notifyProcess }

  // The directory is created once, if it is not already there. The only write
  // this plugin makes outside its own state file.
  Process {
    id: mkdirProcess
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  FileView {
    id: stateFile
    path: root.statePath
    watchChanges: true
    printErrors: false
    onFileChanged: reload()
    onLoaded: {
      root.items = Todo.parse(text()).items
      root.loaded = true
    }
    // No file yet is an empty list, not an error.
    onLoadFailed: root.loaded = true
  }

  Component.onCompleted: mkdirProcess.running = true
}
