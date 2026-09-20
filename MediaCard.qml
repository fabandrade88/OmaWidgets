import QtQuick
import qs.Commons
import "model/Format.js" as Format
import "model/Media.js" as Media

// What is playing, with the transport.
Card {
  id: root

  property var media: null
  property var config: ({})

  // Guarded accessors, for the moment during a hot-reload when the service is
  // gone but the card has not been torn down yet.
  readonly property var track: media ? media.track : Media.empty()
  readonly property bool hasMedia: !!media && media.hasMedia
  readonly property bool showArt: config.albumArt !== false && track.artUrl !== ""

  title: hasMedia ? (track.title !== "" ? track.title : track.artist) : "Nothing playing"
  glyph: "󰝚"
  meta: hasMedia
    ? Format.joinMeta([track.artist !== "" && track.title !== "" ? track.artist : "", track.appName])
    : (media && media.anyPlayerRunning ? "No track loaded" : "No media player")

  Row {
    width: parent.width
    spacing: Style.spacing.lg
    visible: root.hasMedia

    // Art is loaded asynchronously and cached: a cover is tens of kilobytes and
    // the same URL comes back on every position tick.
    Rectangle {
      id: artFrame
      visible: root.showArt
      width: root.compact ? Style.space(48) : Style.space(64)
      height: width
      radius: root.config.tileRadius !== undefined ? Math.min(root.config.tileRadius, width / 2) : Style.cornerRadius
      color: Util.alpha(root.foreground, 0.08)
      clip: true

      Image {
        anchors.fill: parent
        source: root.showArt ? root.track.artUrl : ""
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        cache: true
        sourceSize.width: 256
        sourceSize.height: 256
      }
    }

    Column {
      width: parent.width - (artFrame.visible ? artFrame.width + parent.spacing : 0)
      spacing: Style.spacing.sm
      anchors.verticalCenter: artFrame.visible ? artFrame.verticalCenter : undefined

      Text {
        textFormat: Text.PlainText
        width: parent.width
        visible: root.track.album !== ""
        text: root.track.album
        color: Qt.darker(root.foreground, 1.45)
        font.family: root.fontFamily
        font.pixelSize: Style.font.caption
        elide: Text.ElideRight
      }

      MeterBar {
        width: parent.width
        visible: root.track.progress >= 0
        value: root.track.progress
      }

      Row {
        width: parent.width
        visible: root.track.progress >= 0

        Text {
          textFormat: Text.PlainText
          text: Format.duration(root.track.position) || "0m"
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }

        Item { width: Math.max(0, parent.width - parent.children[0].width - remaining.width); height: 1 }

        Text {
          id: remaining
          textFormat: Text.PlainText
          text: Format.duration(root.track.length)
          color: Qt.darker(root.foreground, 1.45)
          font.family: root.fontFamily
          font.pixelSize: Style.font.caption
        }
      }

      MediaControls {
        track: root.track
        onPreviousRequested: if (root.media) root.media.previous()
        onToggleRequested: if (root.media) root.media.toggle()
        onNextRequested: if (root.media) root.media.next()
      }
    }
  }

  Text {
    textFormat: Text.PlainText
    width: parent.width
    visible: !root.hasMedia
    text: root.media && root.media.anyPlayerRunning
      ? "A player is running but has no track loaded."
      : "Start Spotify, a browser tab, or any MPRIS player."
    color: Qt.darker(root.foreground, 1.45)
    font.family: root.fontFamily
    font.pixelSize: Style.font.caption
    wrapMode: Text.WordWrap
  }
}
