pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices
import "./network"

Singleton {
    id: root

    readonly property bool wifiEnabled: RyokuServices.Network.wifiRadio
    readonly property bool ethernet: RyokuServices.Network.kind === "ethernet"

    property bool wifiScanning: false
    property var wifiConnectTarget: null
    property var wrapperCache: ({})

    function wrap(accessPoint) {
        let wrapper = root.wrapperCache[accessPoint.ssid];
        if (!wrapper) {
            wrapper = wifiAccessPointComponent.createObject(root);
            root.wrapperCache[accessPoint.ssid] = wrapper;
        }
        wrapper.lastIpcObject = accessPoint;
        return wrapper;
    }

    Component {
        id: wifiAccessPointComponent
        WifiAccessPoint {}
    }

    readonly property var wifiNetworks: RyokuServices.Network.accessPoints.map(root.wrap)

    readonly property var friendlyWifiNetworks: [...root.wifiNetworks].sort((a, b) => {
        if (a.active !== b.active) return a.active ? -1 : 1;
        if (a.saved !== b.saved) return a.saved ? -1 : 1;
        return b.strength - a.strength;
    })

    readonly property var active: root.wifiNetworks.find(network => network?.active) ?? null
    readonly property string wifiStatus: root.ethernet || RyokuServices.Network.wifiConnectivity === "Connected"
        ? "connected"
        : !root.wifiEnabled
            ? "disabled"
            : root.wifiConnectTarget !== null
                ? "connecting"
                : "disconnected"
    readonly property string networkName: root.ethernet ? "Ethernet" : RyokuServices.Network.activeSsid
    readonly property string materialSymbol: root.ethernet ? "lan"
        : root.wifiStatus === "connected"
            ? ((root.active?.strength ?? 0) > 83 ? "signal_wifi_4_bar"
                : (root.active?.strength ?? 0) > 67 ? "network_wifi"
                : (root.active?.strength ?? 0) > 50 ? "network_wifi_3_bar"
                : (root.active?.strength ?? 0) > 33 ? "network_wifi_2_bar"
                : (root.active?.strength ?? 0) > 17 ? "network_wifi_1_bar"
                : "signal_wifi_0_bar")
            : root.wifiStatus === "connecting"
                ? "signal_wifi_statusbar_not_connected"
                : root.wifiStatus === "disconnected"
                    ? "wifi_find"
                    : "signal_wifi_off"

    function enableWifi(enabled = true) {
        RyokuServices.Network.setWifiEnabled(enabled);
    }

    function toggleWifi() {
        root.enableWifi(!root.wifiEnabled);
    }

    function rescanWifi() {
        root.wifiScanning = true;
        RyokuServices.Network.refresh();
        scanTimeout.restart();
    }

    function connectToWifiNetwork(accessPoint) {
        accessPoint.askingPassword = false;
        if (accessPoint.isSecure && !accessPoint.saved && !accessPoint.active) {
            accessPoint.askingPassword = true;
            return;
        }
        root.wifiConnectTarget = accessPoint;
        connectTimeout.restart();
        RyokuServices.Network.connectWifi(accessPoint.ssid, "", accessPoint.bssid);
    }

    function changePassword(network, password) {
        network.askingPassword = false;
        root.wifiConnectTarget = network;
        connectTimeout.restart();
        RyokuServices.Network.connectWifi(network.ssid, password, network.bssid);
    }

    function openPublicWifiPortal() {
        Quickshell.execDetached(["xdg-open", "https://nmcheck.gnome.org/"]);
    }

    Timer {
        id: scanTimeout
        interval: 3000
        onTriggered: root.wifiScanning = false
    }

    Timer {
        id: connectTimeout
        interval: 10000
        onTriggered: root.wifiConnectTarget = null
    }

    Connections {
        target: RyokuServices.Network
        function onAccessPointsChanged() {
            root.wifiScanning = false;
        }
        function onActiveSsidChanged() {
            if (root.wifiConnectTarget !== null && root.wifiConnectTarget.ssid === RyokuServices.Network.activeSsid)
                root.wifiConnectTarget = null;
        }
    }
}
