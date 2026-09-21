import QtQuick
import QtQuick.Effects
import qs.Commons
import "../ui"
import "../model/Media.js" as Media

// The media tile: the cover as a small square where the other tiles put their
// ring, and the track underneath.
//
// Art filled the whole tile before, which looked good and read badly — the title
// sat on top of whatever the cover happened to be behind it, and the tile no
// longer matched the row it was in. A square of art in the ring's place keeps the
// grid regular and leaves the text on the tile's own background.
Tile {
  id: root

  property var media: null
  property var config: ({})
  // See TileGrid: on an arrangeable surface the first tap selects.
  property bool activatable: true

  readonly property var track: media ? media.track : Media.empty()
  readonly property bool hasMedia: !!media && media.hasMedia
  readonly property bool showArt: config.albumArt !== false && track.artUrl !== "" && hasMedia

  // Tile draws the ring, the title and the artist; the art replaces the ring
  // when there is one.
  glyph: hasMedia && !showArt ? "󰝚" : ""
  value: hasMedia ? (track.title !== "" ? track.title : track.artist) : ""
  caption: hasMedia && track.title !== "" ? track.artist : ""
  fraction: hasMedia && !showArt ? track.progress : -1
  interactive: hasMedia && track.canTogglePlaying && activatable
  onActivated: if (media) media.toggle()

  // Sits exactly where Tile's ring sits, so a row of tiles stays a row. Null
  // without a cover, which is what lets Tile fall back to its ring.
  artwork: showArt ? artComponent : null

  // Assigned to a property rather than declared loose: Tile's default property
  // is its overlay, which takes Items, and a bare Component would land there.
  property Component artComponent: Component {
    Item {
      // Rectangle.clip clips to the bounding box, not to the radius, so a
      // rounded frame around an image needs an actual mask.
      Rectangle {
        id: coverMask
        anchors.fill: parent
        visible: false
        layer.enabled: true
        radius: Math.min(width, height) * 0.22
        color: "white"
      }

      Rectangle {
        anchors.fill: parent
        radius: coverMask.radius
        color: Util.alpha(Color.popups.text, 0.08)
      }

      Image {
        anchors.fill: parent
        source: root.showArt ? root.track.artUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 256
        sourceSize.height: 256
        layer.enabled: true
        layer.effect: MultiEffect {
          maskEnabled: true
          maskSource: coverMask
          maskThresholdMin: 0.5
          maskSpreadAtMin: 0.1
        }
      }

      // Progress along the bottom edge of the cover, since the ring is gone.
      Rectangle {
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.track.progress >= 0 ? parent.width * root.track.progress : 0
        height: Math.max(2, parent.height * 0.06)
        radius: height / 2
        color: Color.accent
        Behavior on width { NumberAnimation { duration: 400 } }
      }
    }
  }

  MediaControls {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.spacing.xs
    visible: root.hasMedia && root.hot
    compact: true
    track: root.track
    onPreviousRequested: if (root.media) root.media.previous()
    onToggleRequested: if (root.media) root.media.toggle()
    onNextRequested: if (root.media) root.media.next()
  }

  Text {
    textFormat: Text.PlainText
    anchors.centerIn: parent
    visible: !root.hasMedia
    text: "—"
    color: Qt.darker(Color.popups.text, 1.45)
    font.family: Style.font.family
    font.pixelSize: Style.font.display
  }
}
