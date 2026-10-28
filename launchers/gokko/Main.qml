//@ pragma UseQApplication

import QtQuick
import Quickshell
import "upstream" as Gokko

// Gokko Spotlight as a first-class Ryoku launcher. The Gokko bar and this
// launcher intentionally share ~/.config/macbar/settings.json.
Scope {
    id: root

    property bool openRequested: false
    property string monitor: ""
    property bool closing: false
    readonly property bool shown: root.openRequested || root.closing

    readonly property var hostScreen: {
        const list = Quickshell.screens;
        if (root.monitor) {
            for (const screen of list) {
                if (screen.name === root.monitor)
                    return screen;
            }
        }
        return Quickshell.primaryScreen ?? (list.length > 0 ? list[0] : null);
    }

    // Register the bundled UI fonts in this Quickshell process as well as in Gokko's bar.
    FontLoader { source: Qt.resolvedUrl("upstream/assets/fonts/OpenRunde-Regular.otf") }
    FontLoader { source: Qt.resolvedUrl("upstream/assets/fonts/OpenRunde-Semibold.otf") }

    Gokko.MacBar {
        id: spotlight
        launcherOnly: true
        launcherMonitor: root.hostScreen ? root.hostScreen.name : root.monitor
        launcherOpenRequested: root.openRequested
    }

    function show(mon) {
        if (mon)
            root.monitor = mon;
        root.closing = false;
        root.openRequested = true;
    }

    function hide() {
        if (!root.openRequested && !root.closing)
            return;
        root.closing = true;
        root.openRequested = false;
    }

    function toggle(mon) {
        if (root.openRequested || root.closing)
            root.hide();
        else
            root.show(mon);
    }

    function stateDump() {
        return { open: root.openRequested, query: spotlight.launcherQuery };
    }

    function dismissedBySurface() {
        if (!root.openRequested)
            return;
        root.closing = true;
        root.openRequested = false;
    }

    Timer {
        id: closeSettler
        interval: 500
        onTriggered: root.closing = false
    }

    onClosingChanged: {
        if (root.closing)
            closeSettler.restart();
        else
            closeSettler.stop();
    }

    Connections {
        target: spotlight
        function onLauncherDismissed() { root.dismissedBySurface(); }
    }
}
