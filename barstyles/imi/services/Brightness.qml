pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices

Singleton {
    id: root

    component Monitor: QtObject {
        id: monitor
        required property string screenName
        readonly property bool isInternal: /^(eDP|LVDS|DSI)/.test(screenName)
        readonly property var ddc: (RyokuServices.Devices.ddcMonitors ?? []).find(m => m.label === screenName) ?? null
        readonly property bool ready: monitor.isInternal
            ? RyokuServices.Devices.backlightAvailable
            : monitor.ddc !== null
        property real ddcValue: 0.5
        readonly property real brightness: monitor.isInternal
            ? (RyokuServices.Devices.backlightAvailable ? RyokuServices.Devices.backlightPct / 100 : 0.5)
            : monitor.ddcValue

        function setBrightness(value) {
            const pct = Math.max(1, Math.min(100, Math.round(value * 100)));
            if (monitor.isInternal) {
                RyokuServices.Devices.setBacklight(pct);
                return;
            }
            if (monitor.ddc === null) return;
            monitor.ddcValue = pct / 100;
            RyokuServices.Devices.setBrightness(monitor.ddc.bus, pct);
        }
    }

    Component {
        id: monitorComponent
        Monitor {}
    }

    readonly property list<Monitor> monitors: Quickshell.screens.map(screen => monitorComponent.createObject(root, {
        "screenName": screen.name
    }))

    function getMonitorForScreen(screen) {
        return root.monitors.find(monitor => monitor.screenName === (screen?.name ?? "")) ?? null;
    }
}
