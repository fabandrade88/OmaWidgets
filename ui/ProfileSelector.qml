import QtQuick
import qs.Commons
import qs.Ui
import "../model/Power.js" as Power

// Saver / Balanced / Performance, as one segmented control.
//
// Only the profiles the running daemon actually reported get a segment, so a
// machine without power-profiles-daemon shows an explanatory line instead of
// three buttons that would do nothing. Every click goes back through
// PowerService.setProfile, which re-checks the name against the allowlist.
Item {
  id: root

  property var profiles: []
  property string active: ""
  property bool busy: false
  property int cursorIndex: -1

  signal selected(string profile)

  readonly property color foreground: Color.popups.text
  readonly property color dim: Qt.darker(foreground, 1.45)

  visible: profiles.length > 0
  width: parent ? parent.width : implicitWidth
  implicitHeight: row.implicitHeight

  Row {
    id: row
    width: parent.width
    spacing: Style.spacing.xs

    Repeater {
      model: root.profiles

      BorderSurface {
        id: segment

        readonly property bool isActive: modelData === root.active
        readonly property bool hasCursor: index === root.cursorIndex
        readonly property bool hot: mouse.containsMouse || hasCursor

        width: (root.width - Style.spacing.xs * Math.max(0, root.profiles.length - 1))
          / Math.max(1, root.profiles.length)
        implicitHeight: Math.max(Style.spacing.controlHeight, label.implicitHeight + Style.spacing.md * 2)
        radius: Style.cornerRadius
        color: isActive ? Style.selectedAccentFill : (hot ? Style.hoverFill : Style.normalFill)
        borderSpec: Border.controlSpec(isActive ? "selected" : (hot ? "hover" : "normal"),
          root.foreground, Color.accent, Color.urgent)
        opacity: root.busy ? 0.6 : 1

        Column {
          id: label
          anchors.centerIn: parent
          spacing: Style.space(1)

          Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Power.profileIcon(modelData)
            color: segment.isActive ? Color.accent : (segment.hot ? root.foreground : root.dim)
            font.family: Style.font.family
            font.pixelSize: Style.font.icon
          }

          Text {
            textFormat: Text.PlainText
            anchors.horizontalCenter: parent.horizontalCenter
            text: Power.profileLabel(modelData)
            color: segment.isActive ? root.foreground : root.dim
            font.family: Style.font.family
            font.pixelSize: Style.font.caption
            font.bold: segment.isActive
          }
        }

        MouseArea {
          id: mouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          enabled: !root.busy
          onClicked: root.selected(modelData)
        }
      }
    }
  }
}
