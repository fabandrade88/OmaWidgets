import QtQuick
import Quickshell
import Quickshell.Io
import "../model/Todo.js" as Todo
import "../model/TodoList.js" as TodoList

// The to-do list: what is on it, and the file it lives in.
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
  //
  // The clock is its own component; this exposes what the cards read so a card
  // still talks to one service rather than reaching through it.

  PomodoroClock {
    id: pomodoro
    config: root.config
    onPhaseEnded: function (ended, next) { root.phaseEnded(ended, next) }
  }

  readonly property alias phase: pomodoro.phase
  readonly property alias remaining: pomodoro.remaining
  readonly property alias running: pomodoro.running
  readonly property alias completedFocus: pomodoro.completedFocus
  readonly property alias phaseProgress: pomodoro.phaseProgress
  readonly property alias remainingLabel: pomodoro.remainingLabel
  readonly property alias phaseLabel: pomodoro.phaseLabel
  readonly property alias timing: pomodoro.timing

  signal phaseEnded(string endedPhase, string nextPhase)

  function toggleRunning() { pomodoro.toggleRunning() }
  function resetPhase() { pomodoro.resetPhase() }
  function skip() { pomodoro.skip() }
  function startPhase(next) { pomodoro.startPhase(next) }
  function alarm(endedPhase) { pomodoro.alarm(endedPhase) }

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

  readonly property bool oversized: stateFile.oversized

  function save() {
    // Refusing to write over a file that could not be read keeps a list nobody
    // could see from being replaced by an empty one.
    if (!loaded || oversized) return
    writer.setText(Todo.serialize({ items: root.items }))
  }

  Timer {
    // A minute is enough to move a deadline from calm to soon, and nothing else
    // on this card changes faster. The countdown keeps its own second hand.
    interval: 60000
    repeat: true
    running: root.active
    triggeredOnStart: true
    onTriggered: root.clock++
  }

  // Writing is a separate view: GuardedFile owns reading, and a writer that
  // does not watch cannot race its own change notification.
  FileView {
    id: writer
    path: root.statePath
    printErrors: false
    atomicWrites: true
  }

  // The directory is created once, if it is not already there. The only write
  // this plugin makes outside its own state file.
  Process {
    id: mkdirProcess
    command: ["mkdir", "-p", root.stateDir]
    onExited: stateFile.reload()
  }

  GuardedFile {
    id: stateFile
    path: root.statePath
    maxBytes: Todo.MAX_FILE
    onTextLoaded: function (body) {
      root.items = Todo.parse(body).items
      root.loaded = true
    }
    // No file yet is an empty list, not an error.
    onMissing: root.loaded = true
  }

  Component.onCompleted: mkdirProcess.running = true
}
