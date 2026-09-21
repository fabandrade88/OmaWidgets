import QtQuick
import "model/Format.js" as Format
import "model/Gpu.js" as Gpu
import "model/Layout.js" as Layout
import "model/Power.js" as Power

// Compact mode: one square per reading, rounded, in a grid.
//
// Not the full cards with tighter padding — the Performance card alone carries
// three unrelated readings, and crushing them together is what made the old
// compact mode barely more compact. Each reading gets its own tile with the one
// number it exists to show.
Item {
  id: root

  required property var system
  required property var gpuService
  required property var pods
  required property var power
  required property var media
  property var settings: null
  property var presence: Layout.defaultState()

  signal profileRequested(string profile)

  readonly property var tiles: Layout.visibleTiles(settings, presence)
  readonly property int side: settings.tileSize
  readonly property int columnCount: Math.min(settings.columns, Math.max(1, tiles.length))

  readonly property var gpu: gpuService ? gpuService.gpu : Gpu.empty()
  readonly property var gpuHeadline: gpuService ? gpuService.headline : ({ kind: "absent", value: -1 })

  implicitWidth: grid.implicitWidth
  implicitHeight: grid.implicitHeight

  Grid {
    id: grid
    columns: root.columnCount
    spacing: root.settings.spacing

    Repeater {
      model: root.tiles

      Loader {
        readonly property string tileId: modelData
        width: root.side
        height: root.side

        sourceComponent: {
          if (tileId === Layout.TILE_CPU) return cpuTile
          if (tileId === Layout.TILE_MEMORY) return memoryTile
          if (tileId === Layout.TILE_GPU) return gpuTile
          if (tileId === Layout.TILE_PODS) return podsTileComponent
          if (tileId === Layout.TILE_BATTERY) return batteryTile
          if (tileId === Layout.TILE_POWER) return powerTile
          if (tileId === Layout.TILE_MEDIA) return mediaTile
          return null
        }
      }
    }
  }

  component MetricTile: Tile {
    height: root.side
    radius: root.settings.tileRadius
    backgroundOpacity: root.settings.opacity
  }

  Component {
    id: cpuTile
    MetricTile {
      glyph: "󰍛"
      label: Layout.tileLabel(Layout.TILE_CPU)
      value: Format.isKnown(root.system.cpuLoad) ? Format.percent(root.system.cpuLoad) : "—"
      caption: Format.celsius(root.system.cpuTemperature)
      fraction: root.system.cpuLoad
      alert: Format.isKnown(root.system.cpuTemperature) && root.system.cpuTemperature >= 85000
    }
  }

  Component {
    id: memoryTile
    MetricTile {
      glyph: "󰘚"
      label: Layout.tileLabel(Layout.TILE_MEMORY)
      value: Format.isKnown(root.system.memory.fraction)
        ? Format.percent(root.system.memory.fraction) : "—"
      caption: root.system.memory.totalKib > 0 ? Format.fromKib(root.system.memory.usedKib) : ""
      fraction: root.system.memory.fraction
      alert: Format.isKnown(root.system.memory.fraction) && root.system.memory.fraction >= 0.9
    }
  }

  Component {
    id: gpuTile
    MetricTile {
      glyph: "󰢮"
      label: Layout.tileLabel(Layout.TILE_GPU)
      // A driver with no busy counter leads with its clock, so the biggest
      // number on the tile is always something that was measured.
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

  Component {
    id: podsTileComponent
    PodsTile {
      height: root.side
      radius: root.settings.tileRadius
      backgroundOpacity: root.settings.opacity
      pods: root.pods
      config: root.settings
    }
  }

  Component {
    id: batteryTile
    MetricTile {
      glyph: root.power.icon
      label: Layout.tileLabel(Layout.TILE_BATTERY)
      value: root.power.present ? Format.percent(root.power.fraction) : "—"
      caption: Format.duration(root.power.secondsRemaining)
        || (root.power.charging ? "charging" : "")
      fraction: root.power.present ? root.power.fraction : -1
      alert: root.power.low
    }
  }

  Component {
    id: powerTile
    MetricTile {
      glyph: Power.profileIcon(root.power.activeProfile)
      label: Layout.tileLabel(Layout.TILE_POWER)
      value: Power.profileLabel(root.power.activeProfile) || "—"
      caption: root.power.onBattery ? "on battery" : "on AC"
      // The ring shows where this profile sits on the saver-to-performance
      // scale, so the tile carries the same information the segmented control
      // does on the full card.
      fraction: {
        var at = root.power.profiles.indexOf(root.power.activeProfile)
        if (at < 0 || root.power.profiles.length < 2) return -1
        return at / (root.power.profiles.length - 1)
      }
      // Tapping cycles to the next profile; the full card has the three
      // buttons, but a tile has room for one gesture.
      interactive: root.power.profilesAvailable
      onActivated: root.power.cycleProfile(1)
    }
  }

  Component {
    id: mediaTile
    MediaTile {
      height: root.side
      radius: root.settings.tileRadius
      backgroundOpacity: root.settings.opacity
      media: root.media
      config: root.settings
    }
  }
}
