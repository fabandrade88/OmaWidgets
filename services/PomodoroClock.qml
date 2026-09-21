import QtQuick
import Quickshell.Io
import "../model/Pomodoro.js" as Pomodoro

// The Pomodoro clock: which phase is running, how much of it is left, and the
// alarm when it ends.
//
// Split from TodoService, which owns the list and its file. The two share a
// card because they are one activity, but a countdown and a durable list are
// not one job.
Item {
  id: root

  property var config: ({})

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
  //
  // What happens then is the user's call. `autoAdvance` chains the rounds the
  // way a kitchen timer would; with it off — the default — the next phase is
  // loaded and waits to be started, so a break you did not take cannot count
  // down without you.
  function advance(announce) {
    var ended = phase
    if (ended === Pomodoro.FOCUS) completedFocus += 1
    var next = Pomodoro.nextPhase(ended, completedFocus, timing)
    setPhase(next)
    running = announce === true && config.autoAdvance === true
    if (announce === true) {
      phaseEnded(ended, next)
      alarm(ended)
    }
  }

  function skip() { advance(false) }

  // Picks a phase outright, which is what the card's three buttons do. Starting
  // the phase already showing pauses it instead, so one button is both.
  function startPhase(next) {
    if (!Pomodoro.isPhase(next)) return
    if (phase === next) {
      toggleRunning()
      return
    }
    setPhase(next)
    running = true
  }

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

  Timer {
    // A clock, so a second. It runs only while the phase does.
    interval: 1000
    repeat: true
    running: root.running
    onTriggered: {
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
}
