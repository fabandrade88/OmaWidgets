import QtQuick
import qs.Commons
import qs.Ui
import "../model/Update.js" as Update

// What version this is, whether a newer one has been published, and the one
// command that installs it.
//
// The button does not update anything itself: it opens a terminal running
// Omarchy's own `omarchy plugin update`, which shows a diff of what would
// change and asks before touching the checkout. That review step is the reason
// the plugin never writes its own code.
Column {
  id: root

  required property var config
  property var updates: null

  signal checkRequested()
  signal updateRequested()
  signal flagToggled(string key)

  readonly property string installed: updates ? updates.installedVersion : ""
  readonly property string latest: updates ? updates.latestVersion : ""
  readonly property string outcome: updates ? updates.outcome : Update.UNKNOWN
  readonly property bool checking: !!updates && updates.checking
  readonly property string failure: updates ? updates.error : ""

  readonly property string summary: {
    if (installed === "") return "version unknown"
    if (checking) return installed + " · checking"
    if (outcome === Update.AVAILABLE) return latest + " available"
    if (outcome === Update.CURRENT) return installed + " · up to date"
    return installed
  }

  readonly property color foreground: Color.popups.text

  spacing: Style.spacing.md

  Text {
    textFormat: Text.PlainText
    width: parent.width
    text: {
      if (!root.config.updateCheck && root.latest === "") return "Daily checks are off. This is version " + root.installed + "."
      if (root.checking) return "Checking for a newer version…"
      if (root.failure !== "") return root.failure + ". This is version " + root.installed + "."
      if (root.outcome === Update.AVAILABLE)
        return "Version " + root.latest + " has been published. You have " + root.installed + "."
      if (root.outcome === Update.CURRENT) return "Version " + root.installed + " is the latest."
      return "This is version " + root.installed + "."
    }
    color: root.outcome === Update.AVAILABLE && root.config.updateCheck
      ? Color.accent : Qt.darker(root.foreground, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  Row {
    width: parent.width
    spacing: Style.spacing.sm

    Button {
      text: "Check now"
      bordered: true
      foreground: root.foreground
      enabled: !root.checking
      onClicked: root.checkRequested()
    }

    Button {
      text: "Update"
      bordered: true
      selected: true
      foreground: root.foreground
      visible: root.outcome === Update.AVAILABLE
      onClicked: root.updateRequested()
    }
  }

  ToggleRow {
    width: parent.width
    label: "Check for updates"
    description: "Asks GitHub once a day whether a newer version was published. Off, only this button asks. Nothing is installed without you."
    checked: root.config.updateCheck
    onToggled: root.flagToggled("updateCheck")
  }
}
