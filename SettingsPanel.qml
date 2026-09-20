import QtQuick
import qs.Commons
import qs.Ui
import "model/Settings.js" as Settings

// Contents of the bar widget's popup: what the cards show, where they sit, and
// the power profile, close to hand.
//
// It reads the normalised settings and emits an intent for every change; the bar
// widget owns the single write path to shell.json, so this file never touches
// persisted state itself.
Column {
  id: root

  required property var config
  property var power: null
  property bool serviceAvailable: true

  signal desktopToggled()
  signal cardToggled(string card)
  signal positionPicked(string position)
  signal compactToggled()
  signal coreBarsToggled()
  signal overlayRequested()
  signal profileRequested(string profile)
  signal columnsChanged(int columns)
  signal tileSizeChanged(int size)

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  spacing: Style.spacing.md

  PanelHero {
    width: parent.width
    title: "OmaWidgets"
    meta: root.config.desktop ? "Cards on the desktop" : "Cards hidden"
    detail: root.config.position
    foreground: root.foreground
    iconComponent: Component {
      Text {
        textFormat: Text.PlainText
        text: "󰜫"
        color: Color.accent
        font.family: Style.font.family
        font.pixelSize: Style.font.display
      }
    }
  }

  PanelSeparator { width: parent.width }

  ToggleRow {
    width: parent.width
    label: "Show on the desktop"
    description: "Cards sit above the wallpaper and below your windows."
    checked: root.config.desktop
    onToggled: root.desktopToggled()
  }

  ToggleRow {
    width: parent.width
    label: "Compact tiles"
    description: "Small rounded squares, one per reading, instead of the full cards."
    checked: root.config.compact
    onToggled: root.compactToggled()
  }

  StepperRow {
    width: parent.width
    label: "Columns"
    description: root.config.compact
      ? "Tiles across before wrapping to the next row."
      : "Cards across before wrapping to the next row."
    value: root.config.columns
    minimum: 1
    maximum: 6
    onChanged: function (value) { root.columnsChanged(value) }
  }

  StepperRow {
    width: parent.width
    visible: root.config.compact
    label: "Tile size"
    description: "Tiles are square, so one number sizes them."
    value: root.config.tileSize
    minimum: 88
    maximum: 260
    step: 4
    suffix: "px"
    onChanged: function (value) { root.tileSizeChanged(value) }
  }

  ToggleRow {
    width: parent.width
    visible: !root.config.compact
    label: "Per-core bars"
    description: "One bar per CPU thread on the performance card. Full cards only."
    checked: root.config.showCoreBars
    interactive: !root.config.compact
    onToggled: root.coreBarsToggled()
  }

  PanelSeparator { width: parent.width }

  PanelSectionHeader {
    width: parent.width
    text: "Position"
    foreground: root.foreground
  }

  PositionGrid {
    anchors.horizontalCenter: parent.horizontalCenter
    position: root.config.position
    onPicked: function (value) { root.positionPicked(value) }
  }

  PanelSeparator { width: parent.width }

  PanelSectionHeader {
    width: parent.width
    text: "Cards"
    foreground: root.foreground
  }

  Repeater {
    model: Settings.KNOWN_CARDS

    ToggleRow {
      width: root.width
      label: Settings.cardName(modelData)
      checked: root.config.cards.indexOf(modelData) !== -1
      onToggled: root.cardToggled(modelData)
    }
  }

  PanelSeparator {
    width: parent.width
    visible: root.power && root.power.profilesAvailable
  }

  PanelSectionHeader {
    width: parent.width
    visible: root.power && root.power.profilesAvailable
    text: "Power profile"
    foreground: root.foreground
  }

  ProfileSelector {
    width: parent.width
    profiles: root.power ? root.power.profiles : []
    active: root.power ? root.power.activeProfile : ""
    busy: root.power ? root.power.busy : false
    onSelected: function (profile) { root.profileRequested(profile) }
  }

  PanelSeparator { width: parent.width }

  PanelActionButton {
    anchors.horizontalCenter: parent.horizontalCenter
    iconText: "󰊓"
    tooltipText: "Open the full-screen overlay"
    foreground: root.foreground
    bordered: true
    onClicked: root.overlayRequested()
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: !root.serviceAvailable
    // A replacement bar receives a service-less facade by design, so the live
    // readings are unavailable there. Saying so beats controls that quietly fail.
    text: "Live readings need the built-in Omarchy bar. A replacement bar gets no "
      + "access to this plugin's service."
    color: Color.urgent
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
