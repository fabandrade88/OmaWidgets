import QtQuick
import qs.Commons
import "model/Media.js" as Media

// The media tile, in two forms.
//
// With cover art there is nothing better to show than the art, so it fills the
// square and the track sits over a scrim at the bottom. Without it, the tile
// falls back to the same ring the other tiles use — track progress around a
// music note — so a row of tiles stays a row of tiles.
Tile {
  id: root

  property var media: null
  property var config: ({})

  readonly property var track: media ? media.track : Media.empty()
  readonly property bool hasMedia: !!media && media.hasMedia
  readonly property bool showArt: config.albumArt !== false && track.artUrl !== "" && hasMedia

  // Tile's own ring-and-reading layout is used only when there is no art; with
  // art, everything is drawn in the overlay instead.
  glyph: showArt || !hasMedia ? "" : "󰝚"
  value: showArt || !hasMedia ? "" : (track.title !== "" ? track.title : track.artist)
  caption: showArt || !hasMedia || track.title === "" ? "" : track.artist
  fraction: showArt || !hasMedia ? -1 : track.progress
  interactive: hasMedia && track.canTogglePlaying
  onActivated: if (media) media.toggle()

  Image {
    anchors.fill: parent
    visible: root.showArt
    source: root.showArt ? root.track.artUrl : ""
    fillMode: Image.PreserveAspectCrop
    asynchronous: true
    cache: true
    sourceSize.width: 320
    sourceSize.height: 320
    opacity: 0.55
  }

  // Keeps the labels readable over any cover.
  Rectangle {
    anchors.fill: parent
    visible: root.showArt
    gradient: Gradient {
      GradientStop { position: 0.0; color: Util.alpha(Color.popups.background, 0.25) }
      GradientStop { position: 0.55; color: Util.alpha(Color.popups.background, 0.72) }
      GradientStop { position: 1.0; color: Util.alpha(Color.popups.background, 0.92) }
    }
  }

  Column {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Style.spacing.md
    anchors.bottomMargin: Style.spacing.lg
    visible: root.showArt
    spacing: 0

    Text {
      textFormat: Text.PlainText
      width: parent.width
      text: root.track.title !== "" ? root.track.title : root.track.artist
      color: Color.popups.text
      font.family: Style.font.family
      font.pixelSize: Style.font.body
      font.bold: true
      elide: Text.ElideRight
    }

    Text {
      textFormat: Text.PlainText
      width: parent.width
      visible: root.track.artist !== "" && root.track.title !== ""
      text: root.track.artist
      color: Qt.darker(Color.popups.text, 1.45)
      font.family: Style.font.family
      font.pixelSize: Style.font.caption
      elide: Text.ElideRight
    }
  }

  MediaControls {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Style.spacing.sm
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
