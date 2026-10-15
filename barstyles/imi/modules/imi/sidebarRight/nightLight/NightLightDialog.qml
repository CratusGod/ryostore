import "../../../.."
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../../common/functions"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import shell.services as RyokuServices

WindowDialog {
    id: root
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)
    backgroundHeight: 700

    WindowDialogTitle {
        text: Translation.tr("Eye protection")
    }
    
    WindowDialogSectionHeader {
        text: Translation.tr("Night Light")
    }

    WindowDialogSeparator {
        Layout.topMargin: -Appearance.spacing.space300
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: nightLightColumn
        Layout.topMargin: -Appearance.spacing.space200
        Layout.fillWidth: true

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "check"
            text: Translation.tr("Enable now")
            checked: RyokuServices.Nightlight.on
            onToggleRequested: RyokuServices.Nightlight.toggle()
        }

        ConfigSwitch {
            anchors {
                left: parent.left
                right: parent.right
            }
            iconSize: Appearance.font.pixelSize.larger
            buttonIcon: "night_sight_auto"
            text: Translation.tr("Automatic")
            checked: RyokuServices.Nightlight.schedule === "sun"
            onToggleRequested: RyokuServices.Nightlight.setSchedule(!checked)
        }

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Appearance.spacing.space50
                rightMargin: Appearance.spacing.space50
            }
            text: Translation.tr("Intensity")
            from: 6500
            to: 1200
            stopIndicatorValues: [5000, to]
            value: RyokuServices.Nightlight.temperature
            onMoved: RyokuServices.Nightlight.setTemperature(value)
            tooltipContent: `${Math.round(value)}K`
        }
    }

    WindowDialogSectionHeader {
        text: Translation.tr("Brightness")
    }

    WindowDialogSeparator {
        Layout.topMargin: -Appearance.spacing.space300
        Layout.leftMargin: 0
        Layout.rightMargin: 0
    }

    Column {
        id: brightnessColumn
        Layout.topMargin: -Appearance.spacing.space200
        Layout.fillWidth: true

        WindowDialogSlider {
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Appearance.spacing.space50
                rightMargin: Appearance.spacing.space50
            }
            enabled: root.brightnessMonitor?.ready ?? false
            value: root.brightnessMonitor?.brightness ?? 0
            onMoved: {
                if (root.brightnessMonitor)
                    root.brightnessMonitor.setBrightness(value);
            }
        }
    }
    
    WindowDialogButtonRow {
        Layout.fillWidth: true

        Item {
            Layout.fillWidth: true
        }

        DialogButton {
            buttonText: Translation.tr("Done")
            onClicked: root.dismiss()
        }
    }
}
