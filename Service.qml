import QtQuick
import Quickshell.Io
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
    : (shell ? Settings.fromBarConfig(shell.barConfig, pluginId) : ({})))

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

  MediaService {
    id: mediaService
    active: root.sampling
    preferredPlayer: root.config.preferredPlayer
  }

  DesktopSurface {
    id: desktop
    system: systemService
    gpuService: gpuMetrics
    pods: podsService
    power: powerService
    media: mediaService
    config: root.config
    showCards: root.config.desktop
    onProfileRequested: function (profile) { root.setProfile(profile) }
  }

  IpcHandler {
    target: "omawidgets"

    // Summons the overlay. `omarchy-shell shell toggle <plugin-id> '{}'` does the
    // same thing; this target exists so a Hyprland keybind can read plainly.
    function toggle(): string { return root.toggleOverlay() ? "ok" : "unavailable" }
    function show(): string { return root.shell && root.shell.summon(root.pluginId, "{}") ? "ok" : "unavailable" }
    function hide(): string { return root.hideOverlay() ? "ok" : "unavailable" }
    function refresh(): string { root.refresh(); return "ok" }

    // What the media card is showing, for a status line or a script.
    function nowPlaying(): string {
      if (!root.media.hasMedia) return root.media.anyPlayerRunning ? "no track" : "no player"
      var track = root.media.track
      return (track.isPlaying ? "playing" : "paused") + "\t" + track.title + "\t" + track.artist
    }

    function playPause(): string { root.media.toggle(); return "ok" }
    function nextTrack(): string { root.media.next(); return "ok" }
    function previousTrack(): string { root.media.previous(); return "ok" }

    // Reads the current profile, and sets it only through the allowlisted path.
    function profile(): string { return root.power.activeProfile }
    function setProfile(name: string): string { return root.setProfile(name) ? "ok" : "rejected" }
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
