import QtQuick
import "model/Arrange.js" as Arrange
import "model/Settings.js" as Settings

// The plugin's single long-lived instance: it owns every sampler, holds the
// desktop surface, and is what the bar widget and the overlay read from.
//
// One instance means one set of timers no matter how many surfaces are showing.
// Sampling is gated on `sampling`: with no desktop cards and nothing open, every
// timer is stopped and the plugin costs nothing but the memory it occupies.
Item {
  id: root

  // Injected by the shell host. `shell` is the capability-scoped facade, not the
  // shell itself: it can look up this plugin's own service and lifecycle and
  // nothing else.
  property var shell: null
  property var manifest: null
  property string omarchyPath: ""

  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "io.github.fabandrade88.omawidgets"

  // Settings, from the bar widget when one is mounted and from the host's bar
  // config snapshot before that.
  //
  // The snapshot cannot be the live source: `shell.barConfig` is pushed onto the
  // plugin facade by the host, and only when the plugin registry or the widget
  // registry changes — not when a setting is written. Reading it on every change
  // left the desktop cards one write behind, so picking a position appeared to
  // apply the position picked before it. The bar widget's own `settings` are
  // re-injected by the bar host as soon as they change, so it pushes them here
  // and the cards move on the click that asked them to.
  property var pushedSettings: null

  readonly property var config: Settings.normalize(pushedSettings !== null
    ? pushedSettings
    : (shell ? Arrange.fromBarConfig(shell.barConfig, pluginId) : ({})))

  // Called by the bar widget whenever its injected settings change. Idempotent,
  // because one bar widget instance exists per monitor and each one pushes.
  function applySettings(next) {
    pushedSettings = next === undefined || next === null ? ({}) : next
  }

  // Set by the surfaces that are not the desktop layer, so a closed overlay and
  // a closed popup leave nothing running.
  property bool overlayViewing: false
  property bool panelViewing: false

  readonly property bool focused: overlayViewing || panelViewing
  readonly property bool sampling: config.desktop || focused
  // A surface someone is looking at gets a faster cadence; the desktop layer,
  // glanced at in passing, does not need one.
  readonly property int effectiveIntervalMs: focused
    ? Math.min(1000, config.intervalMs) : config.intervalMs

  readonly property alias probe: hardwareProbe
  readonly property alias system: systemService
  readonly property alias gpuService: gpuMetrics
  readonly property alias pods: podsService
  readonly property alias power: powerService
  readonly property alias media: mediaService
  readonly property alias todos: todoService

  readonly property alias arranger: arranger

  function setProfile(profile) {
    return powerService.setProfile(profile)
  }

  function cycleProfile(direction) {
    return powerService.cycleProfile(direction)
  }

  function refresh() {
    hardwareProbe.refresh()
    podsService.refresh()
    powerService.refresh()
    if (sampling) {
      systemService.sample()
      gpuMetrics.sample()
    }
  }

  function toggleOverlay() {
    if (!shell || typeof shell.toggle !== "function") return false
    return shell.toggle(pluginId, "{}")
  }

  function hideOverlay() {
    if (!shell || typeof shell.hide !== "function") return false
    return shell.hide(pluginId)
  }

  HardwareProbe {
    id: hardwareProbe
  }

  SystemService {
    id: systemService
    probe: hardwareProbe
    active: root.sampling
    intervalMs: root.effectiveIntervalMs
  }

  GpuService {
    id: gpuMetrics
    probe: hardwareProbe
    active: root.sampling
    intervalMs: root.effectiveIntervalMs
  }

  PodsService {
    id: podsService
  }

  PowerService {
    id: powerService
    probe: hardwareProbe
  }

  Arranger {
    id: arranger
    config: root.config
    presence: ({ hasPods: podsService.hasBattery, hasMedia: mediaService.hasMedia })
  }

  TodoService {
    id: todoService
    config: root.config
    active: root.sampling
  }

  MediaService {
    id: mediaService
    active: root.sampling
    preferredPlayer: root.config.preferredPlayer
  }

  ServiceIpc {
    service: root
  }

  DesktopSurface {
    id: desktop
    system: systemService
    gpuService: gpuMetrics
    pods: podsService
    power: powerService
    media: mediaService
    todos: todoService
    config: root.config
    showCards: root.config.desktop
    selectedId: arranger.selectedCard
    onProfileRequested: function (profile) { root.setProfile(profile) }
    onSelectRequested: function (id) { arranger.select(id) }
    onOrderRequested: function (ids) { arranger.applyOrder(ids) }
    onHideRequested: function (id) { arranger.hide(id) }
  }

  // The probe finishes after the services are built, so the first samples are
  // taken once it knows where to read.
  Connections {
    target: hardwareProbe
    function onRefreshed() {
      // The probe can report back while the plugin is being torn down for a
      // hot-reload, at which point `root` is already gone.
      if (!root || !root.sampling) return
      systemService.sample()
      gpuMetrics.sample()
    }
  }
}
