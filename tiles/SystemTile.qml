import QtQuick
import qs.Commons
import "../ui"
import "../model/Format.js" as Format
import "../model/Gpu.js" as Gpu
import "../model/Layout.js" as Layout
import "../model/Sysfs.js" as Sysfs

// CPU, memory and GPU in one wide tile.
//
// They belong together: they are the three halves of "what is this machine
// doing", and reading them as three separate squares scattered through a grid is
// worse than reading them side by side. So the Performance tile spans two
// columns and holds three gauges, in the shape of the reference.
Tile {
  id: root

  property var system: null
  property var gpuService: null
  property var config: ({})

  readonly property real cpuLoad: system ? system.cpuLoad : Format.UNKNOWN
  readonly property real cpuTemperature: system ? system.cpuTemperature : Format.UNKNOWN
  readonly property var memory: system ? system.memory : Sysfs.parseMeminfo("")
  readonly property var gpu: gpuService ? gpuService.gpu : Gpu.empty()
  readonly property var gpuHeadline: gpuService ? gpuService.headline : ({ kind: "absent", value: -1 })

  readonly property real gaugeSize: Math.min(Style.space(50), height * 0.42)

  // Tile's own single-reading layout is unused here; the row below replaces it.
  glyph: ""
  value: ""
  caption: ""
  fraction: -1
  // Square is Tile's default; this one is as wide as its content.
  implicitWidth: width

  Row {
    anchors.centerIn: parent
    width: parent.width - root.contentLeftInset - root.contentRightInset
    spacing: 0

    MetricGauge {
      width: parent.width / 3
      ringSize: root.gaugeSize
      glyph: "󰍛"
      value: Format.isKnown(root.cpuLoad) ? Format.percent(root.cpuLoad) : "—"
      caption: Format.celsius(root.cpuTemperature) || Layout.tileLabel("system")
      fraction: root.cpuLoad
      alert: Format.isKnown(root.cpuTemperature) && root.cpuTemperature >= 85000
    }

    MetricGauge {
      width: parent.width / 3
      ringSize: root.gaugeSize
      glyph: "󰘚"
      value: Format.isKnown(root.memory.fraction) ? Format.percent(root.memory.fraction) : "—"
      caption: root.memory.totalKib > 0 ? Format.fromKib(root.memory.usedKib) : ""
      fraction: root.memory.fraction
      alert: Format.isKnown(root.memory.fraction) && root.memory.fraction >= 0.9
    }

    MetricGauge {
      width: parent.width / 3
      ringSize: root.gaugeSize
      glyph: "󰢮"
      // A driver with no busy counter leads with its clock, so the number on
      // the tile is always something that was measured.
      value: {
        if (!root.gpu.present) return "—"
        if (root.gpuHeadline.kind === "busy") return Format.percent(root.gpu.busy)
        if (Format.isKnown(root.gpu.frequency)) return Format.megahertz(root.gpu.frequency) || "idle"
        return "—"
      }
      caption: Format.celsius(root.gpu.temperature)
      fraction: root.gpuHeadline.value
    }
  }
}
