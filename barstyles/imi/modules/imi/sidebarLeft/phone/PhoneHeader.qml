import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../phone"
import "../../phone/device_glyph.js" as DeviceGlyph
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var device: null
    property bool rosterOpen: false

    signal toggleRoster()

    property real appear: 1

    implicitHeight: headerRow.implicitHeight

    RowLayout {
        id: headerRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.space100

        FilterChip {
            id: deviceChip
            objectName: "deviceChip"
            readonly property var device: root.device
            chipIcon: DeviceGlyph.forType(root.device?.type)
            label: root.device ? (root.device.name || root.device.id) : Translation.tr("No device")
            trailingIcon: PhoneConnect.devices.length > 0
                ? (root.rosterOpen ? "expand_less" : "expand_more") : ""
            toggled: true
            enabled: PhoneConnect.devices.length > 0
            onClicked: root.toggleRoster()
        }

        Badge {
            id: connectionPill
            implicitHeight: deviceChip.implicitHeight
            colBackground: "transparent"
            colText: Appearance.colors.colOnSurfaceVariant
            visible: root.device !== null
            badgeIcon: root.device?.reachable ? "wifi" : "wifi_off"
            label: {
                if (!root.device?.reachable) return Translation.tr("Offline");
                const cellular = root.device?.cellularNetworkType ?? "";
                if (cellular !== "") return cellular;
                const address = root.device?.reachableAddresses?.[0] ?? "";
                return address !== "" ? address : Translation.tr("Connected");
            }
        }

        Badge {
            id: batteryPill
            implicitHeight: deviceChip.implicitHeight
            colBackground: "transparent"
            colText: Appearance.colors.colOnSurfaceVariant
            visible: root.device?.batteryAvailable ?? false
            badgeIcon: root.device?.batteryCharging ? "battery_charging_full" : "battery_full"
            label: Translation.tr("%1%").arg(String(root.device?.batteryCharge ?? 0))
        }

        Item {
            Layout.fillWidth: true
        }
    }
}
