import QtQuick
import qs.Commons
import "model/Media.js" as Media

// The media tile: cover art filling the square, the track over a scrim at the
// bottom, and the transport on hover.
//
// Art is the one thing on a tile worth showing at tile size, so it takes the
// whole square instead of sitting in a corner.
Tile {
  id: root

  property var media: null
  property var config: ({})

  readonly property var track: media ? media.track : Media.empty()
  readonly property bool hasMedia: !!media && media.hasMedia
  readonly property bool showArt: config.albumArt !== false && track.artUrl !== "" && hasMedia

  glyph: showArt ? "" : "󰝚"
  label: hasMedia ? "" : "NOW PLAYING"
  value: ""
  caption: ""
  fraction: hasMedia ? track.progress : -1
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
    // Clipped to the tile's own rounded corners rather than overflowing them.
    layer.enabled: true
    layer.effect: null
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
    visible: root.hasMedia
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
    anchors.centerIn: parent
    anchors.verticalCenterOffset: -Style.space(6)
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
