import QtQuick
import qs.Commons

// Sample history as a column of thin bars.
//
// Deliberately not a Canvas: Canvas rasterises on the CPU and repaints the whole
// surface on every sample, which is a poor trade for a strip this small inside a
// process that runs all session. A Repeater over a fixed-length model creates its
// delegates once and then only changes their heights, which the scene graph
// handles on the GPU.
Item {
  id: root

  property var series: []
  property color fill: Color.accent
  property real barWidth: Math.max(2, Style.space(2))
  property real gap: Math.max(1, Style.space(1))

  readonly property color dimFill: Util.alpha(fill, 0.35)

  implicitHeight: Style.space(28)
  implicitWidth: Style.space(90)

  Row {
    anchors.fill: parent
    // Newest sample sits at the trailing edge, so the strip reads left to right
    // like the rest of the card.
    layoutDirection: Qt.LeftToRight
    spacing: root.gap

    Repeater {
      model: root.series

      Item {
        // Every bar shares the leftover width evenly, so a narrower card keeps
        // the same number of samples instead of clipping the oldest ones.
        width: Math.max(1, (root.width - root.gap * Math.max(0, root.series.length - 1))
          / Math.max(1, root.series.length))
        height: root.height

        Rectangle {
          anchors.bottom: parent.bottom
          width: parent.width
          // An unknown sample (-1) draws nothing at all. A known zero still draws
          // a hairline, so a genuinely idle stretch is visibly a measurement
          // rather than a gap in the record.
          height: modelData < 0 ? 0 : Math.max(1, parent.height * Math.min(1, modelData))
          radius: Style.cornerRadius > 0 ? width / 2 : 0
          color: index === root.series.length - 1 ? root.fill : root.dimFill

          Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
          }
        }
      }
    }
  }
}
