import QtQuick
import qs.Commons
import "model/Format.js" as Format
import "model/Power.js" as Power

// The power profile, and the control that changes it.
//
// Changing the profile is the only thing this plugin does that alters system
// state. It goes through Omarchy's own omarchy-powerprofiles-set so the choice is
// remembered per power source the way the stock power panel remembers it, and the
// name is allowlisted twice before it reaches an argv.
Card {
  id: root

  property var power: null
  property var config: ({})
  property int cursorIndex: -1

  signal profileRequested(string profile)

  // Guarded accessors, for the moment during a hot-reload when the service is
  // gone but the card has not been torn down yet.
  readonly property string activeProfile: power ? power.activeProfile : ""
  readonly property var profiles: power ? power.profiles : []
  readonly property bool busy: !!power && power.busy
  readonly property bool onBattery: !!power && power.onBattery
  readonly property bool profilesAvailable: !!power && power.profilesAvailable
  readonly property string lastError: power ? power.lastError : ""

  readonly property string activeLabel: Power.profileLabel(activeProfile)
  readonly property string activeDescription: Power.profileDescription(activeProfile)

  title: "Power profile"
  glyph: Power.profileIcon(activeProfile)
  meta: Format.joinMeta([
    activeProfile !== "" ? activeLabel : "",
    onBattery ? "on battery" : "on AC"
  ])

  ProfileSelector {
    width: parent.width
    profiles: root.profiles
    active: root.activeProfile
    busy: root.busy
    cursorIndex: root.cursorIndex
    onSelected: function (profile) { root.profileRequested(profile) }
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: root.activeDescription !== "" && root.lastError === ""
    text: root.activeDescription
    color: Qt.darker(root.foreground, 1.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: !root.profilesAvailable
    text: "No power profiles available. power-profiles-daemon is not running on this machine."
    color: Qt.darker(root.foreground, 1.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: root.lastError !== ""
    // Whatever the helper wrote to stderr, rendered as plain text and length
    // capped by the service that captured it.
    text: root.lastError
    color: Color.urgent
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
