import QtQuick
import qs.Commons
import "model/Format.js" as Format
import "model/Gpu.js" as Gpu
import "model/Sysfs.js" as Sysfs

// CPU, memory and GPU on one card: a gauge and recent history for the CPU, then
// a labelled meter for each of the other two.
Card {
  id: root

  property var system: null
  property var gpuService: null
  property var config: ({})

  // One guarded accessor per reading the card actually uses. A service is null
  // for a moment while the plugin hot-reloads, and a card that reaches through
  // `system.memory.fraction` fills the shell's log on every reload. Declaring
  // the inputs also says plainly what this card consumes.
  readonly property real cpuLoad: system ? system.cpuLoad : Format.UNKNOWN
  readonly property var coreLoads: system ? system.coreLoads : []
  readonly property var cpuHistory: system ? system.cpuHistory : []
  readonly property real cpuTemperature: system ? system.cpuTemperature : Format.UNKNOWN
  readonly property real cpuFrequency: system ? system.cpuFrequency : Format.UNKNOWN
  readonly property string cpuModel: system ? system.cpuModel : ""
  readonly property int coreCount: system ? system.coreCount : 0
  readonly property var memory: system ? system.memory : Sysfs.parseMeminfo("")
  readonly property real loadOne: system && system.load ? system.load.one : Format.UNKNOWN

  readonly property bool showCoreBars: config.showCoreBars !== false && !compact
  readonly property var gpu: gpuService ? gpuService.gpu : Gpu.empty()
  readonly property var gpuHeadline: gpuService ? gpuService.headline : ({ kind: "absent", value: -1 })

  readonly property bool cpuHot: Format.isKnown(cpuTemperature) && cpuTemperature >= 85000
  readonly property bool memoryTight: Format.isKnown(memory.fraction) && memory.fraction >= 0.9

  title: "Performance"
  glyph: "󰍛"
  meta: Format.joinMeta([
    cpuModel !== "" ? shortModel(cpuModel) : "",
    coreCount > 0 ? coreCount + " threads" : ""
  ])

  // /proc/cpuinfo model names carry marketing noise that does not survive a
  // 268px card, and the family is the part worth keeping.
  function shortModel(name) {
    return String(name || "")
      .replace(/\((R|TM)\)/g, "")
      .replace(/\s+CPU\s+/, " ")
      .replace(/\s+@.*$/, "")
      .replace(/\s+/g, " ")
      .trim()
  }

  function gpuValueLabel() {
    if (!gpu.present) return "—"
    if (gpuHeadline.kind === "busy") return Format.percent(gpu.busy)
    if (Format.isKnown(gpu.frequency)) return Format.megahertz(gpu.frequency) || "idle"
    return "—"
  }

  // The GPU row's trailing detail differs by vendor: a temperature that belongs
  // to the GPU is shown plainly, one shared with the CPU package is marked, and
  // VRAM appears only where a driver reports it.
  function gpuDetailLabel() {
    var parts = []
    if (Format.isKnown(gpu.temperature))
      parts.push(Format.celsius(gpu.temperature) + (gpu.temperatureIsShared ? " soc" : ""))
    if (Format.isKnown(gpu.memoryUsedMib) && Format.isKnown(gpu.memoryTotalMib))
      parts.push(Format.fromMib(gpu.memoryUsedMib))
    return Format.joinMeta(parts, " ")
  }

  Row {
    width: parent.width
    spacing: Style.spacing.lg

    RingGauge {
      id: gauge
      width: root.compact ? Style.space(58) : Style.space(72)
      height: width
      value: root.cpuLoad
      fill: root.cpuHot ? Color.urgent : Color.accent
      text: Format.isKnown(root.cpuLoad) ? Format.percent(root.cpuLoad) : "—"
      caption: Format.isKnown(root.cpuTemperature)
        ? Format.celsius(root.cpuTemperature) : "CPU"
    }

    Column {
      width: parent.width - gauge.width - parent.spacing
      spacing: Style.spacing.sm
      anchors.verticalCenter: gauge.verticalCenter

      Text {
        textFormat: Text.PlainText
        text: "CPU"
        color: Qt.darker(root.foreground, 1.45)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        font.bold: true
        font.letterSpacing: 1.1
      }

      HistoryGraph {
        width: parent.width
        height: root.compact ? Style.space(20) : Style.space(26)
        series: root.cpuHistory
        fill: root.cpuHot ? Color.urgent : Color.accent
      }

      CoreBars {
        visible: root.showCoreBars
        width: parent.width
        height: Style.space(16)
        loads: root.coreLoads
      }

      Text {
        textFormat: Text.PlainText
        visible: Format.isKnown(root.cpuFrequency)
        text: Format.joinMeta([
          Format.megahertz(root.cpuFrequency),
          Format.isKnown(root.loadOne) ? "load " + root.loadOne.toFixed(2) : ""
        ])
        color: Qt.darker(root.foreground, 1.45)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
      }
    }
  }

  MetricRow {
    label: "MEMORY"
    value: Format.isKnown(root.memory.fraction)
      ? Format.percent(root.memory.fraction) : "—"
    detail: root.memory.totalKib > 0
      ? Format.fromKib(root.memory.usedKib) + " / " + Format.fromKib(root.memory.totalKib)
      : ""
    fraction: root.memory.fraction
    alert: root.memoryTight
  }

  MetricRow {
    visible: Format.isKnown(root.memory.swapFraction) && root.memory.swapUsedKib > 0
    label: "SWAP"
    value: Format.percent(root.memory.swapFraction)
    detail: Format.fromKib(root.memory.swapUsedKib)
    fraction: root.memory.swapFraction
  }

  MetricRow {
    label: root.gpu.name !== "" ? root.gpu.name.toUpperCase() : "GPU"
    value: root.gpuValueLabel()
    detail: root.gpuDetailLabel()
    fraction: root.gpuHeadline.value
    // Intel has no busy counter without elevated perf access, so its row shows
    // the clock it is running at and says so instead of inventing a percentage.
    showMeter: root.gpu.present && root.gpuHeadline.value >= 0
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: root.gpu.present && root.gpuHeadline.kind === "clock"
    text: "Clock shown: this driver reports no utilisation counter."
    color: Qt.darker(root.foreground, 1.55)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
