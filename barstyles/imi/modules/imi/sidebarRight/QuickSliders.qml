import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

Rectangle {
    id: root

    property int entranceTrigger: -1
    onEntranceTriggerChanged: {
        sliderWave.park();
        sliderWave.enter();
    }
    property var screen: root.QsWindow.window?.screen
    property var brightnessMonitor: Brightness.getMonitorForScreen(screen)

    StaggerWave {
        id: sliderWave
        target: root
        items: [volumeLoader, micLoader, brightnessLoader]
        leadIn: 80
    }

    implicitWidth: contentItem.implicitWidth + root.horizontalPadding * 2
    implicitHeight: contentItem.implicitHeight + root.verticalPadding * 2
    radius: Appearance.rounding.normal
    color: Appearance.colors.colLayer1
    property real verticalPadding: Appearance.spacing.space50
    property real horizontalPadding: Appearance.spacing.space150

    Column {
        id: contentItem
        anchors {
            fill: parent
            leftMargin: root.horizontalPadding
            rightMargin: root.horizontalPadding
            topMargin: root.verticalPadding
            bottomMargin: root.verticalPadding
        }

        StaggerEntrance {
            target: contentItem
        }

        Loader {
            id: brightnessLoader
            property real appear: 1
            anchors {
                left: parent.left
                right: parent.right
            }
            visible: active
            active: Config.options.sidebar.quickSliders.showBrightness
            sourceComponent: QuickSlider {
                entranceTrigger: root.entranceTrigger
                sliderIndex: 0
                materialSymbol: "brightness_medium"
                enabled: root.brightnessMonitor?.ready ?? false
                shownValue: root.brightnessMonitor?.brightness ?? 0
                tooltipContent: `${Math.round((root.brightnessMonitor?.brightness ?? 0) * 100)}%`
                onMoved: {
                    if (root.brightnessMonitor)
                        root.brightnessMonitor.setBrightness(value);
                }
            }
        }

        Row {
            id: bottomRow
            width: parent.width
            height: Math.max(volumeLoader.implicitHeight, micLoader.implicitHeight)
            spacing: Appearance.spacing.space50

            StaggerEntrance {
                target: bottomRow
            }

            Loader {
                id: volumeLoader
                property real appear: 1
                width: micLoader.active ? (parent.width - parent.spacing) / 2 : parent.width
                visible: active
                active: Config.options.sidebar.quickSliders.showVolume
                sourceComponent: QuickSlider {
                    entranceTrigger: root.entranceTrigger
                    sliderIndex: 1
                    materialSymbol: "volume_up"
                    shownValue: Audio.sink?.audio?.volume ?? 0
                    onMoved: {
                        if (Audio.sink?.audio)
                            Audio.sink.audio.volume = value
                    }
                }
            }

            Loader {
                id: micLoader
                property real appear: 1
                width: volumeLoader.active ? (parent.width - parent.spacing) / 2 : parent.width
                visible: active
                active: Config.options.sidebar.quickSliders.showMic
                sourceComponent: QuickSlider {
                    entranceTrigger: root.entranceTrigger
                    sliderIndex: 2
                    materialSymbol: "mic"
                    shownValue: Audio.source?.audio?.volume ?? 0
                    onMoved: {
                        if (Audio.source?.audio)
                            Audio.source.audio.volume = value
                    }
                }
            }
        }
    }

    component QuickSlider: StyledSlider {
        id: quickSlider
        required property string materialSymbol
        property string secondaryMaterialSymbol
        property int entranceTrigger: -1
        property int sliderIndex: 0
        property real shownValue: 0
        property bool entranceParked: false
        value: entranceParked ? 0 : shownValue
        onEntranceTriggerChanged: {
            quickSlider.endSweep();
            quickSlider.valueGlide = false;
            quickSlider.entranceParked = true;
            quickSlider.valueGlide = true;
            sweepTimer.restart();
        }
        function endSweep() {
            sweepRestore.stop();
            quickSlider.valueVelocity =
                Qt.binding(() => Appearance.animation.elementMoveFast.velocity);
        }
        onShownValueChanged: {
            if (sweepRestore.running)
                quickSlider.endSweep();
        }
        Timer {
            id: sweepTimer
            interval: Appearance.animation.scale(80 + quickSlider.sliderIndex * 50)
            onTriggered: {
                const sweepMs = Appearance.animation.scale(650);
                if (quickSlider.shownValue > 0.01) {
                    quickSlider.valueVelocity = quickSlider.shownValue / (sweepMs / 1000);
                    sweepRestore.interval = sweepMs + 80;
                    sweepRestore.restart();
                }
                quickSlider.entranceParked = false;
            }
        }
        Timer {
            id: sweepRestore
            onTriggered: quickSlider.endSweep()
        }
        configuration: StyledSlider.Configuration.M
        stopIndicatorValues: []
        dividerValues: secondaryMaterialSymbol.length > 0 ? [secondaryIcon.iconLocation] : []

        MaterialSymbol {
            id: icon
            property bool nearFull: quickSlider.value >= 0.9
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearFull ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearFull ? Appearance.spacing.space175 : Appearance.spacing.space100
            }
            iconSize: 20
            color: nearFull ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: quickSlider.materialSymbol
            rotation: quickSlider.value * 360

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on anchors.rightMargin {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }
        }

        MaterialSymbol {
            id: secondaryIcon
            visible: secondaryMaterialSymbol.length > 0
            property real iconLocation: 0.3
            property bool nearIcon: iconLocation - quickSlider.value <= 0.1 && iconLocation - quickSlider.value > (quickSlider.handleWidth + 8 - 14) / quickSlider.effectiveDraggingWidth
            anchors {
                verticalCenter: quickSlider.verticalCenter
                right: nearIcon ? quickSlider.handle.right : quickSlider.right
                rightMargin: nearIcon ? Appearance.spacing.space175 : (1 - iconLocation) * quickSlider.effectiveDraggingWidth + quickSlider.rightPadding + 8
            }
            iconSize: 20
            color: quickSlider.value >= iconLocation - 0.1 ? Appearance.colors.colOnPrimary : Appearance.colors.colOnSecondaryContainer
            text: secondaryMaterialSymbol

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
        }
    }
}
