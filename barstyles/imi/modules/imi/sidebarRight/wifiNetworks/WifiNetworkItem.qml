import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import "../../../../services/network"
import QtQuick
import QtQuick.Layouts

DialogListItem {
    id: root
    required property WifiAccessPoint wifiNetwork
    property bool connecting: false
    property bool materialShapeChars: false

    signal connectRequested()
    signal passwordSubmitted(string password)
    signal passwordCancelled()
    signal portalRequested()

    enabled: !(root.connecting && !wifiNetwork?.active)
    active: (wifiNetwork?.askingPassword || wifiNetwork?.active) ?? false
    onClicked: root.connectRequested()

    contentItem: ColumnLayout {
        anchors {
            fill: parent
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
        }
        spacing: 0

        RowLayout {
            spacing: Appearance.spacing.space150
            MaterialSymbol {
                iconSize: Appearance.font.pixelSize.larger
                property int strength: root.wifiNetwork?.strength ?? 0
                text: strength > 80 ? "signal_wifi_4_bar" : strength > 60 ? "network_wifi_3_bar" : strength > 40 ? "network_wifi_2_bar" : strength > 20 ? "network_wifi_1_bar" : "signal_wifi_0_bar"
                color: Appearance.colors.colOnSurfaceVariant
            }
            MarqueeText {
                Layout.fillWidth: true
                color: Appearance.colors.colOnSurfaceVariant
                text: root.wifiNetwork?.ssid ?? Translation.tr("Unknown")
            }
            MaterialSymbol {
                visible: (root.wifiNetwork?.isSecure || root.wifiNetwork?.active) ?? false
                text: root.wifiNetwork?.active ? "check" : root.connecting ? "settings_ethernet" : "lock"
                iconSize: Appearance.font.pixelSize.larger
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        ColumnLayout {
            id: passwordPrompt
            Layout.topMargin: Appearance.spacing.space100
            visible: root.wifiNetwork?.askingPassword ?? false

            PasswordField {
                id: passwordField
                materialShapeChars: passwordField.masked && root.materialShapeChars
                Layout.fillWidth: true
                placeholderText: Translation.tr("Password")
                colBackground: Appearance.colors.colLayer4
                colText: Appearance.colors.colOnLayer4

                onAccepted: {
                    root.passwordSubmitted(passwordField.text);
                }
            }

            RowLayout {
                Layout.fillWidth: true

                Item {
                    Layout.fillWidth: true
                }

                DialogButton {
                    buttonText: Translation.tr("Cancel")
                    onClicked: {
                        root.passwordCancelled();
                    }
                }

                DialogButton {
                    buttonText: Translation.tr("Connect")
                    onClicked: {
                        root.passwordSubmitted(passwordField.text);
                    }
                }
            }
        }

        ColumnLayout {
            id: publicWifiPortal
            Layout.topMargin: Appearance.spacing.space100
            visible: (root.wifiNetwork?.active && (root.wifiNetwork?.security ?? "").trim().length === 0) ?? false

            RowLayout {
                DialogButton {
                    Layout.fillWidth: true
                    buttonText: Translation.tr("Open network portal")
                    colBackground: Appearance.colors.colLayer4
                    colBackgroundHover: Appearance.colors.colLayer4Hover
                    colRipple: Appearance.colors.colLayer4Active
                    onClicked: root.portalRequested()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
