import Quickshell
import QtQuick
import shell.services as Ryoku
import "."

// The system side of the media pill. The pick, the sticky "last sounding player"
// rule and the wallpaper/radio filtering all live in Ryoku's Media singleton, so
// the bar shows exactly what the rest of the shell does, with no second MPRIS
// client.
Scope {
    id: root

    readonly property var player: Ryoku.Media.player

    readonly property bool present: Ryoku.Media.present
    readonly property bool playing: Ryoku.Media.playing

    readonly property string title: {
        if (root.player === null)
            return ""
        return (root.player.trackTitle || "") !== "" ? root.player.trackTitle
            : (root.player.identity ?? "")
    }
    readonly property string artist: root.player?.trackArtist ?? ""

    readonly property string artUrl: {
        if (root.player === null)
            return ""
        return root.player.trackArtUrl ?? ""
    }

    readonly property bool volumeAvailable: root.player !== null && root.player.volumeSupported

    function changeVolume(direction) {
        if (root.player === null || !root.player.volumeSupported || !root.player.canControl)
            return
        const v = Math.max(0, Math.min(1, (root.player.volume ?? 0) + direction * 0.05))
        root.player.volume = v
    }

    function togglePlaying() {
        Ryoku.Media.toggle()
    }

    function next() {
        if (root.player !== null && root.player.canGoNext)
            root.player.next()
    }

    function previous() {
        if (root.player !== null && root.player.canGoPrevious)
            root.player.previous()
    }
}
