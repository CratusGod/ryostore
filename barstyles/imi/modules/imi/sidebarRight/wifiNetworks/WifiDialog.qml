import "../../../.."
import "../../../../services"
import "../../../../services/network"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell

WindowDialog {
    id: root
    backgroundHeight: 600

    RowLayout {
        Layout.fillWidth: true
        spacing: Appearance.spacing.space100

        WindowDialogTitle {
            Layout.fillWidth: true
            text: Translation.tr("Connect to Wi-Fi")
        }

        DialogButton {
            id: rescanButton
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: implicitHeight

            enabled: !Network.wifiScanning
            opacity: enabled ? 1 : 0.4
            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            onClicked: Network.rescanWifi()

            contentItem: MaterialSymbol {
                anchors.fill: parent
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: "refresh"
                iconSize: Appearance.font.pixelSize.larger
                color: rescanButton.enabled ? rescanButton.colEnabled : rescanButton.colDisabled

                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
            }

            StyledToolTip {
                text: Translation.tr("Rescan networks")
            }
        }
    }
    WindowDialogSeparator {
        visible: !Network.wifiScanning
    }
    StyledIndeterminateProgressBar {
        visible: Network.wifiScanning
        Layout.fillWidth: true
        Layout.topMargin: -Appearance.spacing.space100
        Layout.bottomMargin: -Appearance.spacing.space100
        Layout.leftMargin: -root.contentPadding
        Layout.rightMargin: -root.contentPadding
    }
    StyledListView {
        Layout.fillHeight: true
        Layout.fillWidth: true
        Layout.topMargin: -Appearance.spacing.space200
        Layout.bottomMargin: -Appearance.spacing.space200
        Layout.leftMargin: -root.contentPadding
        Layout.rightMargin: -root.contentPadding

        clip: true
        spacing: 0
        animateAppearance: false

        model: ScriptModel {
            values: Network.friendlyWifiNetworks
        }
        delegate: WifiNetworkItem {
            required property WifiAccessPoint modelData
            wifiNetwork: modelData
            width: ListView.view.width
            connecting: Network.wifiConnectTarget === modelData
            materialShapeChars: Config.options.lock.materialShapeChars
            onConnectRequested: Network.connectToWifiNetwork(modelData)
            onPasswordSubmitted: password => Network.changePassword(modelData, password)
            onPasswordCancelled: modelData.askingPassword = false
            onPortalRequested: {
                Network.openPublicWifiPortal();
                GlobalStates.sidebarRightOpen = false;
            }
        }
    }
    WindowDialogSeparator {}
    WindowDialogButtonRow {
        DialogButton {
            buttonText: Translation.tr("Details")
            onClicked: {
                Quickshell.execDetached(["bash", "-c", `${Network.ethernet ? Config.options.apps.networkEthernet : Config.options.apps.network}`]);
                GlobalStates.sidebarRightOpen = false;
            }
        }

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}