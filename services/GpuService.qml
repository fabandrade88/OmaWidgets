import QtQuick
import Quickshell.Io
import "../model/Gpu.js" as Gpu
import "../model/Series.js" as Series

// GPU sampling.
//
// AMD and Intel are read entirely from sysfs, so they cost the same as the CPU
// card: a few file reloads on a timer that stops when nothing is visible.
// NVIDIA has no sysfs counters at all, so it is the one card that runs a helper
// binary — and only when the probe actually found nvidia-smi, and only while a
// surface is showing.
Item {
  id: root

  property bool active: false
  property int intervalMs: 2000
  property var probe: null
  property int historyLength: 40

  readonly property var gpu: reading
  readonly property bool present: reading.present
  readonly property var history: series
  readonly property var headline: Gpu.headline(reading)
  readonly property bool usesHelper: nvidiaSmiPath !== ""
  // program(), not path(): this one is executed rather than read, and the sysfs
  // allowlist path() enforces would reject /usr/bin/nvidia-smi outright — which
  // is exactly what it did, silently disabling every NVIDIA card.
  readonly property string nvidiaSmiPath: probe ? probe.program("gpu.nvidiaSmi") : ""

  property var reading: Gpu.empty()
  property var series: Series.create(historyLength)

  // Raw sysfs contents, keyed the way Gpu.fromSysfs expects. Kept as strings so
  // the parsing rules stay in one testable place.
  property var fields: ({})

  readonly property var descriptor: ({
    driver: probe ? probe.text("gpu.driver", "") : "",
    name: probe ? probe.text("gpu.name", "") : "",
    frequencyUnit: probe ? probe.text("gpu.freq.unit", "mhz") : "mhz",
    temperatureIsShared: probe ? probe.flag("gpu.temp.shared") : false
  })

  readonly property bool hasSysfsSource: descriptor.driver !== ""

  function sample() {
    if (nvidiaSmiPath !== "") {
      if (!nvidiaProcess.running) nvidiaProcess.running = true
      return
    }
    if (!hasSysfsSource) return
    var views = [busyFile, temperatureFile, frequencyFile, maxFrequencyFile,
      memoryUsedFile, memoryTotalFile, powerFile]
    for (var i = 0; i < views.length; i++) if (views[i].path !== "") views[i].reload()
  }

  function setField(key, raw) {
    // Reassign the whole object rather than mutating it: a QML binding on
    // `fields` only re-evaluates when the property itself changes.
    var next = ({})
    for (var existing in fields) next[existing] = fields[existing]
    next[key] = String(raw || "").trim()
    fields = next
    rebuild()
  }

  function rebuild() {
    reading = Gpu.fromSysfs(descriptor, fields)
    pushHistory()
  }

  function applyNvidia(raw) {
    reading = Gpu.parseNvidiaSmi(raw)
    pushHistory()
  }

  function pushHistory() {
    var point = Gpu.headline(reading)
    series = Series.push(series, point.value, historyLength)
  }

  onActiveChanged: if (active) sample()
  onDescriptorChanged: if (hasSysfsSource && nvidiaSmiPath === "") rebuild()

  Timer {
    interval: Math.max(500, root.intervalMs)
    running: root.active && (root.hasSysfsSource || root.nvidiaSmiPath !== "")
    repeat: true
    onTriggered: root.sample()
  }

  Process {
    id: nvidiaProcess
    // A fixed argv: the only variable part is the binary path the probe found at
    // /usr/bin/nvidia-smi, and nothing user-supplied is ever appended.
    command: [root.nvidiaSmiPath,
      "--query-gpu=name,utilization.gpu,temperature.gpu,clocks.current.graphics,"
        + "clocks.max.graphics,memory.used,memory.total,power.draw",
      "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      waitForEnd: true
      onStreamFinished: root.applyNvidia(text)
    }
  }

  FileView {
    id: busyFile
    path: root.probe ? root.probe.path("gpu.busy") : ""
    printErrors: false
    onLoaded: root.setField("busy", text())
  }

  FileView {
    id: temperatureFile
    path: root.probe ? root.probe.path("gpu.temp") : ""
    printErrors: false
    onLoaded: root.setField("temperature", text())
  }

  FileView {
    id: frequencyFile
    path: root.probe ? root.probe.path("gpu.freq") : ""
    printErrors: false
    onLoaded: root.setField("frequency", text())
  }

  FileView {
    id: maxFrequencyFile
    path: root.probe ? root.probe.path("gpu.freq.max") : ""
    printErrors: false
    onLoaded: root.setField("maxFrequency", text())
  }

  FileView {
    id: memoryUsedFile
    path: root.probe ? root.probe.path("gpu.mem.used") : ""
    printErrors: false
    onLoaded: root.setField("memoryUsed", text())
  }

  FileView {
    id: memoryTotalFile
    path: root.probe ? root.probe.path("gpu.mem.total") : ""
    printErrors: false
    onLoaded: root.setField("memoryTotal", text())
  }

  FileView {
    id: powerFile
    path: root.probe ? root.probe.path("gpu.power") : ""
    printErrors: false
    onLoaded: root.setField("power", text())
  }
}
