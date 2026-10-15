pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices

Singleton {
    id: root

    readonly property var activePlayer: RyokuServices.Media.player
    readonly property var players: RyokuServices.Media.playerSet
    readonly property bool isPlaying: RyokuServices.Media.playing

    readonly property var meaningfulPlayers: root.players.filter(player =>
        player && !RyokuServices.Media.isWallpaper(player) && !RyokuServices.Media.isRadio(player))
}
