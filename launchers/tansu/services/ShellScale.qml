pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property real minScale: 0.5
    readonly property real maxScale: 3.0
    property var monitors: ({})

    function forScreen(screen) {
        const dpr = screen && screen.devicePixelRatio ? Number(screen.devicePixelRatio) : 1
        return Math.max(root.minScale, Math.min(root.maxScale, isFinite(dpr) && dpr > 0 ? dpr : 1))
    }

    function setScale(monitor, value) {}
    function resetScale(monitor) {}
}
