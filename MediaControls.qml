import QtQuick
import qs.Commons
import qs.Ui

// Previous, play/pause, next. Shared by the media card and the media tile so
// the transport behaves the same in both.
//
// The glyphs are the same codepoints the stock Omarchy media widget uses, so a
// theme or font tuned for one is tuned for both.
//
// Each button is enabled from the player's own capability flags, so a source
// that cannot skip — a live stream, most podcasts — shows the button dimmed and
// inert rather than pretending.
Row {
  id: root

  property var track: null
  property bool compact: false

  signal previousRequested()
  signal toggleRequested()
  signal nextRequested()

  readonly property bool canPrevious: !!track && track.canGoPrevious
  readonly property bool canNext: !!track && track.canGoNext
  readonly property bool canToggle: !!track && track.canTogglePlaying
  readonly property bool playing: !!track && track.isPlaying

  spacing: compact ? Style.spacing.xs : Style.spacing.sm

  component TransportButton: PanelActionButton {
    property bool available: true
    foreground: Color.popups.text
    enabled: available
    opacity: available ? 1 : 0.35
    fontSize: root.compact ? Style.font.body : Style.font.icon
    size: root.compact
      ? Math.max(Style.space(18), Style.font.body + Style.spacing.xs * 2)
      : Math.max(Style.space(26), Style.font.icon + Style.spacing.sm * 2)
  }

  TransportButton {
    iconText: "󰒮"
    tooltipText: "Previous"
    available: root.canPrevious
    onClicked: root.previousRequested()
  }

  TransportButton {
    // The button shows what pressing it does, which is the opposite of the
    // current state.
    iconText: root.playing ? "󰏤" : "󰐊"
    tooltipText: root.playing ? "Pause" : "Play"
    available: root.canToggle
    bordered: !root.compact
    onClicked: root.toggleRequested()
  }

  TransportButton {
    iconText: "󰒭"
    tooltipText: "Next"
    available: root.canNext
    onClicked: root.nextRequested()
  }
}
