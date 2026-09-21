import QtQuick
import qs.Commons

// Per-core load as a row of vertical bars.
//
// The model is the core-load array itself, whose length is fixed by the CPU, so
// the delegates are built once for the life of the card.
Item {
  id: root

  property var loads: []
  property color fill: Color.accent

  // The track is barely there on purpose. At full-height 30% accent it read as a
  // row of solid blocks rather than as empty bars waiting for a reading, which
  // made an idle CPU look like a broken widget.
  readonly property color track: Util.alpha(Color.popups.text, 0.12)
  readonly property int count: Array.isArray(loads) ? loads.length : 0

  // Anything hotter than this gets the theme's urgent colour, which is the same
  // threshold the meters elsewhere on the card use.
  readonly property real hotFraction: 0.85

  visible: count > 0
  implicitHeight: Style.space(22)
  implicitWidth: Style.space(60)

  Row {
    anchors.fill: parent
    spacing: Math.max(1, Style.space(1))

    Repeater {
      // The count, not the array — see HistoryGraph. The core count does not
      // change while the machine is running, so these are built once.
      model: root.count

      Item {
        readonly property real load: index < root.count ? root.loads[index] : -1

        width: Math.max(2, (root.width - Math.max(1, Style.space(1)) * Math.max(0, root.count - 1))
          / Math.max(1, root.count))
        height: root.height

        Rectangle {
          anchors.fill: parent
          radius: Style.cornerRadius > 0 ? width / 2 : 0
          color: root.track
        }

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          // A known zero still draws a hairline, so an idle core is visibly a
          // reading rather than a gap where a bar should be.
          height: parent.load < 0 ? 0 : Math.max(1, parent.height * Math.min(1, parent.load))
          radius: Style.cornerRadius > 0 ? width / 2 : 0
          color: parent.load >= root.hotFraction ? Color.urgent : root.fill

          Behavior on height {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }
}
