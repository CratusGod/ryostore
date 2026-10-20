pragma Singleton
import QtQuick
import Quickshell
import "."

Singleton {
    id: root

    readonly property real minScale: 0.5
    readonly property real maxScale: 3.0

    readonly property var monitors: SettingsService.get("shell.scales", ({}))

    function clampScale(v) {
        const n = Number(v)
        if (!isFinite(n) || n <= 0)
            return 1
        return Math.max(root.minScale, Math.min(root.maxScale, n))
    }

    function userFor(name) {
        const v = name ? Number(root.monitors[name]) : NaN
        return isFinite(v) && v > 0 ? root.clampScale(v) : 1
    }

    function screenByName(name) {
        for (const s of Quickshell.screens)
            if (s.name === name)
                return s
        return null
    }

    function dprFor(name) {
        const s = root.screenByName(name)
        const dpr = s && s.devicePixelRatio ? Number(s.devicePixelRatio) : 1
        return isFinite(dpr) && dpr > 0 ? dpr : 1
    }

    function forScreen(screen) {
        const dpr = screen && screen.devicePixelRatio ? Number(screen.devicePixelRatio) : 1
        return root.clampScale((isFinite(dpr) && dpr > 0 ? dpr : 1)
            * root.userFor(screen ? screen.name : ""))
    }

    function effectiveFor(name) {
        return root.forScreen(root.screenByName(name))
    }

    function setScale(monitor, value) {
        if (!monitor)
            return
        const next = Object.assign({}, root.monitors)
        next[monitor] = Math.round(root.clampScale(value) / root.dprFor(monitor) * 100) / 100
        SettingsService.set("shell.scales", next)
    }

    function resetScale(monitor) {
        if (!monitor)
            return
        const next = Object.assign({}, root.monitors)
        delete next[monitor]
        SettingsService.set("shell.scales", next)
    }
}