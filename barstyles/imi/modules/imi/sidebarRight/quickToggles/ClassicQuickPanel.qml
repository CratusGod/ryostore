import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth

import "classicStyle"
import "../../../common/models/quickToggles"

AbstractQuickPanel {
    id: root
    Layout.alignment: Qt.AlignHCenter
    implicitWidth: buttonGroup.implicitWidth
    implicitHeight: buttonGroup.implicitHeight
    color: "transparent"

    ButtonGroup {
        id: buttonGroup
        spacing: Appearance.spacing.space100
        padding: Appearance.spacing.space100
        color: Appearance.colors.colLayer1

        QuickToggleButton {
            toggleModel: NetworkToggle {}
            altAction: () => root.openWifiDialog()
        }
        QuickToggleButton {
            toggleModel: BluetoothToggle {}
            altAction: () => root.openBluetoothDialog()
        }
        QuickToggleButton {
            toggleModel: NightLightToggle {}
            altAction: () => root.openNightLightDialog()
        }
        QuickToggleButton { toggleModel: GameModeToggle {} }
        QuickToggleButton { toggleModel: IdleInhibitorToggle {} }
        QuickToggleButton {
            toggleModel: MicToggle {}
            altAction: () => root.openAudioInputDialog()
        }
        QuickToggleButton {
            toggleModel: AudioToggle {}
            altAction: () => root.openAudioOutputDialog()
        }
        QuickToggleButton { toggleModel: NotificationToggle {} }
        QuickToggleButton { toggleModel: PowerProfilesToggle {} }
        QuickToggleButton { toggleModel: ScreenSnipToggle {} }
        QuickToggleButton {
            toggleModel: PhoneConnectToggle {}
            altAction: () => root.openPhoneTab()
        }
    }
}
