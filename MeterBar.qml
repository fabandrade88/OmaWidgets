import QtQuick
import qs.Commons

// Thin horizontal fill. Used for load, memory and battery level.
//
// A reading of -1 (the plugin's UNKNOWN) draws an empty track rather than a zero
// fill, because "no sensor" and "idle" should not look the same.
Item {
  id: root

  property real value: -1
  property color fill: Color.accent
  property color track: Util.alpha(Color.popups.text, 0.14)
  property real thickness: Math.max(3, Style.space(4))
  property bool animated: true

  readonly property bool known: value >= 0
  readonly property real clamped: Util.clampAlpha(value)

  implicitHeight: thickness
  implicitWidth: Style.space(80)

  Rectangle {
    id: trackRect
    anchors.fill: parent
    radius: Style.cornerRadius > 0 ? height / 2 : 0
    color: root.track
  }

  Rectangle {
    height: parent.height
    width: root.known ? Math.max(root.clamped > 0 ? 2 : 0, trackRect.width * root.clamped) : 0
    radius: trackRect.radius
    color: root.fill

    // Short enough to read as the same sample moving, long enough that a 2s
    // cadence does not look like a series of jumps.
    Behavior on width {
      enabled: root.animated
      NumberAnimation { duration: 260; easing.type: Easing.OutCubic }
    }
  }
}
