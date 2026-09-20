import QtQuick
import Quickshell.Io
import "model/Sysfs.js" as Sysfs
import "model/Series.js" as Series

// CPU and memory sampling.
//
// One timer drives four FileView reloads and each file reports its own content
// back through onLoaded, so nothing blocks the GUI thread and no value is ever
// read from a stale cache. `active` is the whole performance story: when no
// surface is showing a card, the timer stops and this object costs nothing.
Item {
  id: root

  property bool active: false
  property int intervalMs: 2000
  property var probe: null
  property int historyLength: 40

  readonly property real cpuLoad: cpuSample.overall
  readonly property var coreLoads: cpuSample.cores
  readonly property var cpuHistory: history
  readonly property real cpuTemperature: temperature
  readonly property real cpuFrequency: frequency
  readonly property real cpuMaxFrequency: maxFrequency
  readonly property string cpuModel: probe ? probe.text("cpu.model", "") : ""
  readonly property int coreCount: coreLoads.length

  readonly property var memory: memorySample
  readonly property var load: loadSample

  property var cpuSample: ({ overall: Sysfs.UNKNOWN, cores: [] })
  property var memorySample: Sysfs.parseMeminfo("")
  property var loadSample: ({ one: Sysfs.UNKNOWN, five: Sysfs.UNKNOWN, fifteen: Sysfs.UNKNOWN })
  property var history: Series.create(historyLength)
  property real temperature: Sysfs.UNKNOWN
  property real frequency: Sysfs.UNKNOWN
  property real maxFrequency: Sysfs.UNKNOWN

  // The previous cumulative counters. /proc/stat is monotonic, so a single
  // sample says nothing on its own; load only exists once there are two.
  property var previousStat: null

  function sample() {
    statFile.reload()
    memoryFile.reload()
    loadFile.reload()
    if (temperatureFile.path !== "") temperatureFile.reload()
    if (frequencyFile.path !== "") frequencyFile.reload()
  }

  function applyStat(raw) {
    var next = Sysfs.parseCpuStat(raw)
    if (!next.overall) return
    if (previousStat) {
      cpuSample = Sysfs.cpuLoad(previousStat, next)
      history = Series.push(history, cpuSample.overall, historyLength)
    }
    previousStat = next
  }

  // A stopped timer leaves counters behind that are minutes or hours old. Diffing
  // against them on resume would show one enormous spike, so the baseline is
  // dropped and the first tick after a resume only re-seeds it.
  function resetBaseline() {
    previousStat = null
    cpuSample = ({ overall: Sysfs.UNKNOWN, cores: [] })
  }

  onActiveChanged: {
    if (active) {
      resetBaseline()
      sample()
    }
  }

  Timer {
    interval: Math.max(500, root.intervalMs)
    running: root.active
    repeat: true
    onTriggered: root.sample()
  }

  FileView {
    id: statFile
    path: "/proc/stat"
    printErrors: false
    onLoaded: root.applyStat(text())
  }

  FileView {
    id: memoryFile
    path: "/proc/meminfo"
    printErrors: false
    onLoaded: root.memorySample = Sysfs.parseMeminfo(text())
  }

  FileView {
    id: loadFile
    path: "/proc/loadavg"
    printErrors: false
    onLoaded: root.loadSample = Sysfs.parseLoadAvg(text())
  }

  FileView {
    id: temperatureFile
    path: root.probe ? root.probe.path("cpu.temp") : ""
    printErrors: false
    onLoaded: root.temperature = Sysfs.parseTemperature(text())
    onLoadFailed: root.temperature = Sysfs.UNKNOWN
  }

  FileView {
    id: frequencyFile
    path: root.probe ? root.probe.path("cpu.freq") : ""
    printErrors: false
    onLoaded: root.frequency = Sysfs.parseCpuFrequency(text())
    onLoadFailed: root.frequency = Sysfs.UNKNOWN
  }

  FileView {
    id: maxFrequencyFile
    path: root.probe ? root.probe.path("cpu.freq.max") : ""
    printErrors: false
    onLoaded: root.maxFrequency = Sysfs.parseCpuFrequency(text())
  }
}
