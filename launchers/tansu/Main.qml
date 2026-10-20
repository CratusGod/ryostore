//@ pragma UseQApplication

import QtQuick
import Quickshell
import "services"
import "modules/tansu/launcher"

// Tansu's launcher: the phone-shaped home screen (LauncherSurface.qml), a 1:1
// port of Tansu's launcher phone, wired to Ryoku's backends.
//
// Ryoku seam: the shell's own launcher Scope (modules/launcher/Launcher.qml)
// hosts this file as a launcher variant. It calls show(monitor), hide() and
// toggle(monitor), and reads `shown` to settle open/closed; `stateDump` is the
// shell's probe. The surface itself is `modules/tansu/launcher/LauncherSurface.qml`.
Scope {
    id: root

    // ===== the launcher contract =====
    // The surface binds its `open` to this; `shown` stays true while the
    // drop-out plays, then settles false once the surface says it has finished.
    property bool openRequested: false
    property string monitor: ""
    property bool closing: false
    readonly property bool shown: root.openRequested || root.closing

    readonly property var hostScreen: {
        const list = Quickshell.screens
        if (root.monitor) {
            for (const s of list) {
                if (s.name === root.monitor)
                    return s
            }
        }
        return Quickshell.primaryScreen ?? (list.length > 0 ? list[0] : null)
    }

    function show(mon) {
        if (mon)
            root.monitor = mon
        surface.active = true
        root.closing = false
        root.openRequested = true
    }

    function hide() {
        if (!root.openRequested && !root.closing)
            return
        // `shown` is their OR: flip `closing` first so the window is never
        // unmapped for the turn between the two assignments.
        root.closing = true
        root.openRequested = false
    }

    function toggle(mon) {
        if (root.openRequested || root.closing)
            root.hide()
        else
            root.show(mon)
    }

    function stateDump() {
        const s = surface.item
        return { open: root.openRequested, query: s ? s.query : "" }
    }

    // The surface clears `closing` when its drop-out finishes; this settles the
    // host anyway if the surface never got to play it (a hide before the first
    // frame, or a broken exit).
    Timer {
        id: closeSettler
        interval: 1200
        onTriggered: root.closing = false
    }

    onClosingChanged: {
        if (root.closing)
            closeSettler.restart()
        else
            closeSettler.stop()
    }

    AppSource {
        id: apps
    }

    // Built with the shell, not on the first key press: building it inside
    // show() cost the opening animation its first frames. Maps nothing until
    // `shown` goes true.
    Loader {
        id: surface

        active: true
        asynchronous: true
        sourceComponent: Component {
            LauncherSurface {
                host: root
                source: apps
            }
        }
    }
}
