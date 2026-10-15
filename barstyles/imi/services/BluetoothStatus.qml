pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import Quickshell.Services.UPower
import QtQuick

Singleton {
    id: root

    readonly property bool available: Bluetooth.adapters.values.length > 0
    readonly property bool enabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property BluetoothDevice firstActiveDevice: Bluetooth.defaultAdapter?.devices.values.find(device => device.connected) ?? null
    readonly property int activeDeviceCount: Bluetooth.defaultAdapter?.devices.values.filter(device => device.connected).length ?? 0
    readonly property bool connected: Bluetooth.devices.values.some(d => d.connected)

    function batteryLevelOf(device) {
        if (device?.batteryAvailable)
            return device.battery;
        const addr = device?.address?.toLowerCase() ?? "";
        if (addr) {
            const fallback = (UPower.devices?.values ?? []).find(d =>
                d && !d.isLaptopBattery && (d.nativePath ?? "").toLowerCase().includes(addr));
            if (fallback)
                return fallback.percentage;
        }
        return -1;
    }

    function formatBatterySuffix(device) {
        const level = batteryLevelOf(device);
        return level < 0 ? "" : ` • ${Math.round(level * 100)}%`;
    }

    function sortFunction(a, b) {
        const macRegex = /^([0-9A-Fa-f]{2}-){5}[0-9A-Fa-f]{2}$/;
        const aIsMac = macRegex.test(a.name);
        const bIsMac = macRegex.test(b.name);
        if (aIsMac !== bIsMac)
            return aIsMac ? 1 : -1;

        return a.name.localeCompare(b.name);
    }
    property list<var> connectedDevices: Bluetooth.devices.values.filter(d => d.connected).sort(sortFunction)
    readonly property list<var> batteryDevices: connectedDevices.filter(d => batteryLevelOf(d) >= 0)
    readonly property var lowestBatteryDevice: batteryDevices.reduce((low, d) =>
        low === null || batteryLevelOf(d) < batteryLevelOf(low) ? d : low, null)
    property list<var> pairedButNotConnectedDevices: Bluetooth.devices.values.filter(d => d.paired && !d.connected).sort(sortFunction)
    property list<var> unpairedDevices: Bluetooth.devices.values.filter(d => !d.paired && !d.connected).sort(sortFunction)
    property list<var> friendlyDeviceList: [
        ...connectedDevices,
        ...pairedButNotConnectedDevices,
        ...unpairedDevices
    ]
}
