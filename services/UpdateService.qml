import QtQuick
import Quickshell
import Quickshell.Io
import "../model/Update.js" as Update

// Whether a newer version has been published, and nothing else.
//
// One GET of the published manifest, at most once a day, only when the setting
// says so. It never installs: updating is `omarchy plugin update`, which shows
// the user a diff of what is about to change and asks. A plugin that replaced
// its own code would be skipping exactly that.
Item {
  id: root

  property var config: ({})
  property string repository: ""
  property string installedVersion: ""

  readonly property bool checkAllowed: config.updateCheck === true
  readonly property string url: Update.rawManifestUrl(repository)

  property string latestVersion: ""
  property real lastChecked: 0
  property bool checking: false
  property string error: ""

  readonly property var status: Update.describe(installedVersion, latestVersion)
  readonly property string outcome: status.state
  readonly property bool updateAvailable: outcome === Update.AVAILABLE

  readonly property string stateHome: Quickshell.env("XDG_STATE_HOME")
    || (Quickshell.env("HOME") + "/.local/state")
  readonly property string statePath: stateHome + "/omawidgets/update.json"

  // The setting governs the daily check, not the button: asking outright is an
  // explicit action and always allowed. Without `force` the interval decides,
  // so a shell restarted ten times in an hour still checks once.
  function check(force) {
    if (checking || url === "") return
    if (force !== true && !checkAllowed) return
    if (force !== true && !Update.dueForCheck(lastChecked, Date.now(), Update.INTERVAL_MS)) return
    checking = true
    error = ""
    fetch.get(url)
  }

  // The request itself is bounded three ways — deadline, declared length, and
  // what has actually arrived — by BoundedFetch. Everything here is what to do
  // with the answer.
  BoundedFetch {
    id: fetch
    maxBytes: Update.MAX_BODY
    timeoutMs: 8000

    onLoaded: function (text, bytes) {
      root.checking = false
      root.lastChecked = Date.now()
      var found = Update.versionFrom(text)
      if (found === "") root.error = "The published manifest could not be read"
      else root.latestVersion = found
      root.save()
    }

    onFailed: function (reason) {
      root.checking = false
      root.lastChecked = Date.now()
      root.error = reason === "timed out" ? "GitHub did not answer in time"
        : reason === "too large" ? "The published manifest is too large to be one"
        : "Could not reach GitHub"
      root.save()
    }
  }

  // Remembered between sessions so a restart is not a reason to ask GitHub
  // again, and so the popup can say what it knows before any check runs.
  function save() {
    stateWriter.setText(JSON.stringify({
      lastChecked: Math.round(lastChecked),
      latestVersion: latestVersion
    }))
  }

  FileView {
    id: stateFile
    path: root.statePath
    printErrors: false
    onLoaded: {
      try {
        var saved = JSON.parse(text())
        if (saved && typeof saved === "object") {
          root.lastChecked = Number(saved.lastChecked) || 0
          root.latestVersion = Update.version(saved.latestVersion)
        }
      } catch (e) {
        // A state file we cannot read is one check, not a broken widget.
      }
      root.check(false)
    }
    onLoadFailed: root.check(false)
  }

  FileView {
    id: stateWriter
    path: root.statePath
    printErrors: false
    atomicWrites: true
  }

  // Long-running shells are the normal case on a desktop, so the interval has
  // to be a timer rather than something that only happens at startup.
  Timer {
    interval: 60 * 60 * 1000
    repeat: true
    running: root.checkAllowed
    onTriggered: root.check(false)
  }
}
