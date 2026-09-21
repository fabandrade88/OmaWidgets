import QtQuick
import qs.Commons
import qs.Ui
import "../ui"
import "../model/Settings.js" as Settings

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
  signal settingChanged(string key, int value)
  signal textSettingChanged(string key, string value)
  signal flagToggled(string key)

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

  ToggleRow {
    width: parent.width
    visible: !root.config.compact
    label: "Per-core bars"
    description: "One bar per CPU thread on the performance card."
    checked: root.config.showCoreBars
    onToggled: root.coreBarsToggled()
  }

  PanelSeparator { width: parent.width }

  CardsSection {
    width: parent.width
    config: root.config
    onCardToggled: function (card) { root.cardToggled(card) }
  }

  ExpanderSection {
    width: parent.width
    title: "Layout"
    summary: root.config.position + " \u00b7 " + root.config.columns
      + (root.config.columns === 1 ? " column" : " columns")

    LayoutSettings {
      width: parent.width
      config: root.config
      onPositionPicked: function (value) { root.positionPicked(value) }
      onColumnsChanged: function (value) { root.columnsChanged(value) }
      onTileSizeChanged: function (value) { root.tileSizeChanged(value) }
    }
  }

  ExpanderSection {
    width: parent.width
    // Only worth the space when the card that uses it is switched on.
    visible: root.config.cards.indexOf(Settings.CARD_TODO) !== -1
    title: "To-do and Pomodoro"
    summary: root.config.focusMinutes + "m focus \u00b7 "
      + root.config.shortBreakMinutes + "m / " + root.config.longBreakMinutes + "m breaks"

    TodoSettings {
      width: parent.width
      config: root.config
      onTimingChanged: function (key, value) { root.settingChanged(key, value) }
      onFormatPicked: function (key, value) { root.textSettingChanged(key, value) }
      onFlagToggled: function (key) { root.flagToggled(key) }
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
