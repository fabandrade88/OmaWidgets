import QtQuick

// Overlay entry point. The shell loads this when the plugin is summoned and
// hands it the plugin's own service instance, so the overlay renders the same
// readings the desktop cards are showing rather than starting samplers of its
// own.
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: ""
  // Injected by the panel loader: shell.serviceFor(<this plugin>).
  property var service: null

  property bool wantOpen: false

  readonly property bool opened: wantOpen && surfaceLoader.item !== null
  readonly property string pluginId: manifest && manifest.id
    ? String(manifest.id) : "io.github.fabandrade88.omawidgets"

  // The shell delivers a JSON payload with open(); this overlay takes no
  // parameters, so the argument is accepted and ignored rather than parsed.
  function open(payloadJson) {
    root.wantOpen = true
  }

  function close() {
    root.wantOpen = false
  }

  function toggle() {
    root.wantOpen ? dismiss() : open("{}")
  }

  // Closing from inside the overlay has to tell the shell too, or its
  // openPanelIds still believes the plugin is showing and the next toggle is a
  // no-op.
  function dismiss() {
    root.wantOpen = false
    if (shell && typeof shell.hide === "function") shell.hide(pluginId)
  }

  // Sampling is gated on someone looking, so the overlay says when it is.
  onOpenedChanged: if (service) service.overlayViewing = opened

  // A plugin hot-reload destroys this item. Without clearing the flag the
  // service would keep sampling for an overlay that no longer exists.
  Component.onDestruction: if (service) service.overlayViewing = false

  // The host sets `service` after this item is constructed, so the surface is not
  // built until it is there. Binding cards to a null service first would only
  // fill the shell's log with errors on the way to the same result.
  Loader {
    id: surfaceLoader
    active: root.service !== null
    sourceComponent: surfaceComponent
  }

  Component {
    id: surfaceComponent

    OverlaySurface {
      opened: root.wantOpen
      system: root.service.system
      gpuService: root.service.gpuService
      pods: root.service.pods
      power: root.service.power
      media: root.service.media
      todos: root.service.todos
      config: root.service.config
      onDismissed: root.dismiss()
      onProfileRequested: function (profile) { root.service.setProfile(profile) }
    }
  }
}
