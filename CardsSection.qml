import QtQuick
import "model/Settings.js" as Settings

// Which widgets are on, as a folding list of switches.
//
// A dropdown was tried first and put the list behind a popup inside a
// layer-shell panel — one more thing that can fail to appear. A list you can see
// is better than a list you have to trust, and folded it costs one row.
ExpanderSection {
  id: root

  required property var config

  signal cardToggled(string card)

  readonly property var chosen: config && Array.isArray(config.cards) ? config.cards : []

  title: "Cards"
  summary: chosen.length === 0
    ? "None shown"
    : (chosen.length === Settings.KNOWN_CARDS.length
      ? "All " + chosen.length + " shown"
      : chosen.length + " of " + Settings.KNOWN_CARDS.length + " shown")

  Repeater {
    model: Settings.KNOWN_CARDS

    ToggleRow {
      width: root.width
      label: Settings.cardName(modelData)
      checked: root.chosen.indexOf(modelData) !== -1
      onToggled: root.cardToggled(modelData)
    }
  }
}
