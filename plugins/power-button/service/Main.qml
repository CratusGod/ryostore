pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// Session power actions. No UI here; the panel lists choices, then calls these.
Item {
    id: svc

    property var pluginApi
    property string hibernateCapability: ""
    readonly property bool canHibernate: svc.hibernateCapability === "yes"

    function powerOff() {
        Quickshell.execDetached(["ryoku-host", "power", "poweroff"]);
    }

    function reboot() {
        Quickshell.execDetached(["ryoku-host", "power", "reboot"]);
    }

    function hibernate() {
        if (!svc.canHibernate)
            return;
        svc.lock();
        hibernateDelay.restart();
    }

    // Same path as QS Bar / Super+L: ryoku-shell starts qylock.
    function lock() {
        Quickshell.execDetached(["ryoku-shell", "lock"]);
    }

    function parseLogin1Capability(text) {
        const trimmed = (text ?? "").trim();
        const match = trimmed.match(/^s\s+"([^"]+)"$/);
        return (match ? match[1] : trimmed).toLowerCase();
    }

    Timer {
        id: hibernateDelay
        interval: 900
        onTriggered: Quickshell.execDetached(["ryoku-host", "power", "hibernate"])
    }

    Process {
        command: [
            "busctl", "--system", "call",
            "org.freedesktop.login1",
            "/org/freedesktop/login1",
            "org.freedesktop.login1.Manager",
            "CanHibernate"
        ]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                const capability = svc.parseLogin1Capability(text);
                if (capability.length > 0)
                    svc.hibernateCapability = capability;
            }
        }
    }
}
