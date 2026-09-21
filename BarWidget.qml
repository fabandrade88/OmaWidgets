import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Ui
import "model/Arrange.js" as Arrange
import "model/Layout.js" as Layout
import "model/Settings.js" as Settings

// Bar widget entry point: the icon in the bar, and the popup that configures the
// cards.
//
// It is also the plugin's only write path to shell.json. The service reads the
// same entry but never edits it, so a setting can only change in one place.
Panel {
  id: root

  ipcTarget: "omawidgets-bar"
  manageIpc: false

  property int cursorIndex: -1

  // The host injects `bar` as a capability-scoped facade whose `shell` can look
  // up this plugin's own service and nothing else. Under a replacement bar that
  // facade is service-less by design, so every read here tolerates a null.
  readonly property var service: bar && bar.shell && typeof bar.shell.serviceFor === "function"
    ? bar.shell.serviceFor(moduleName) : null
  readonly property bool serviceAvailable: service !== null
  readonly property var config: Settings.normalize(settings)
  readonly property var power: service ? service.power : null

  readonly property bool desktopShown: config.desktop
  readonly property color iconColor: desktopShown ? barForeground : Qt.darker(barForeground, 1.55)

  // updateEntryInline replaces the whole entry, so every write sends the full
  // normalised object rather than a patch. Normalising on the way out also means
  // a hand-edited file is repaired the first time a setting is touched.
  //
  // The merged result is normalised too, not just the starting point. Merging a
  // raw change into an already-normalised object and persisting that would write
  // an invalid value to shell.json, which the next read then silently replaces
  // with the default — losing the user's setting instead of ignoring bad input.
  function write(changes) {
    if (!bar || !bar.shell || typeof bar.shell.updateEntryInline !== "function") return
    var merged = Settings.normalize(settings)
    for (var key in changes) merged[key] = changes[key]
    var next = Settings.normalize(merged)
    settings = next
    bar.shell.updateEntryInline(moduleName, next)
  }

  function toggleDesktop() {
    write({ desktop: !config.desktop })
  }

  function setPosition(position) {
    if (Layout.POSITIONS.indexOf(String(position)) === -1) return false
    write({ position: position })
    return true
  }

  function setProfile(profile) {
    if (service) service.setProfile(profile)
  }

  function openOverlay() {
    close()
    if (service) service.toggleOverlay()
  }

  // Sampling is gated on someone looking at a surface, so the popup says when it
  // is open. Both edges matter: a popup left open would otherwise poll forever.
  onOpenedChanged: if (service) service.panelViewing = opened
  Component.onDestruction: if (service) service.panelViewing = false

  // The bar host re-injects `settings` as soon as they change on disk, which
  // makes this widget the only live view of them. The service's own snapshot
  // updates a beat later, so the settings are pushed there rather than read
  // back — otherwise the desktop cards act on the previous write.
  function pushSettings() {
    if (service) service.applySettings(settings)
  }

  onSettingsChanged: pushSettings()
  onServiceChanged: pushSettings()
  Component.onCompleted: pushSettings()

  // Selecting, hiding and dragging happen on the desktop surface, which the
  // service owns; persisting the result happens here, because this widget is the
  // only thing that writes shell.json.
  Connections {
    target: root.service ? root.service.arranger : null
    ignoreUnknownSignals: true
    function onCardsChangeRequested(cards) { root.write({ cards: cards }) }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "󰜫"
    foreground: root.iconColor
    tooltipText: root.desktopShown ? "OmaWidgets · cards shown" : "OmaWidgets · cards hidden"
    onPressed: function (pressedButton) {
      if (pressedButton === Qt.RightButton) root.toggleDesktop()
      else if (pressedButton === Qt.MiddleButton) root.openOverlay()
      else root.toggle()
    }
  }

  IpcHandler {
    target: root.ipcTarget
    function open(): void { root.open() }
    function close(): void { root.close() }
    function toggle(): void { root.toggle() }
    // Flips the desktop cards without opening anything, for a Hyprland keybind.
    function toggleDesktop(): string { root.toggleDesktop(); return root.config.desktop ? "shown" : "hidden" }

    // Move the cards from a script or a keybind. Settings.normalize rejects a
    // position that does not exist, so the reply says what actually happened
    // rather than echoing the request back.
    function position(name: string): string {
      root.setPosition(name)
      return root.config.position
    }
  }

  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    focusTarget: keyCatcher
    popoutSwitching: root.popoutSwitching
    popoutSwitchClosing: root.popoutSwitchClosing
    contentWidth: panel.fittedContentWidth(Style.space(320))
    contentHeight: panel.fittedContentHeight(content.implicitHeight)

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onCloseRequested: root.close()
      onTabRequested: function (direction) { root.switchPanel(direction) }
      // Left and right walk the power profiles, which is the one control here
      // worth reaching without the mouse.
      onMoveRequested: function (dx, dy) {
        if (dx !== 0 && root.service) root.service.power.stepProfile(dx)
      }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: content.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        SettingsPanel {
          id: content
          width: parent.width
          config: root.config
          power: root.power
          serviceAvailable: root.serviceAvailable
          onDesktopToggled: root.toggleDesktop()
          onCompactToggled: root.write({ compact: !root.config.compact })
          onCoreBarsToggled: root.write({ showCoreBars: !root.config.showCoreBars })
          // A switch in the folding Cards section. The chosen set goes through
          // applySelection so turning one on keeps the order a drag established.
          onCardToggled: function (card) {
            var chosen = root.config.cards.slice()
            var at = chosen.indexOf(card)
            if (at === -1) chosen.push(card)
            else chosen.splice(at, 1)
            root.write({ cards: Arrange.applySelection(root.config.cards, chosen, Settings.KNOWN_CARDS) })
          }
          onPositionPicked: function (position) { root.setPosition(position) }
          onOverlayRequested: root.openOverlay()
          onProfileRequested: function (profile) { root.setProfile(profile) }
          onColumnsChanged: function (value) { root.write({ columns: value }) }
          onTileSizeChanged: function (value) { root.write({ tileSize: value }) }
          onSettingChanged: function (key, value) {
            var change = ({})
            change[key] = value
            root.write(change)
          }
        }
      }
    }
  }
}
