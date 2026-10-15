pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices

Singleton {
    id: root

    readonly property int barCount: RyokuServices.AudioBars.bars
    readonly property real maxValue: 1
    property int refCount: 0
    readonly property bool active: root.refCount > 0 && RyokuServices.Media.playing
    readonly property var values: RyokuServices.AudioBars.levels

    onActiveChanged: RyokuServices.AudioBars.setActive(root, root.active)
    Component.onDestruction: RyokuServices.AudioBars.setActive(root, false)
}
