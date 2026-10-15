pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../../services"
import "../../.."
import "../../common"
import "../../common/widgets"
import "../settings"

Scope {
    id: root

    property var targetScreen: null

    function screenByName(name) {
        const seen = {};
        for (const screen of Quickshell.screens) {
            if (!screen || seen[screen.name]) continue;
            seen[screen.name] = true;
            if (screen.name === name) return screen;
        }
        return null;
    }

    function focusedScreen() {
        const focused = root.screenByName(WM.focusedMonitor.name);
        if (focused !== null) return focused;
        for (const screen of Quickshell.screens)
            return screen;
        return null;
    }

    Connections {
        target: GlobalStates
        function onSettingsOpenChanged() {
            if (GlobalStates.settingsOpen)
                root.targetScreen = root.focusedScreen();
        }
    }

    PanelWindow {
        id: layer
        screen: root.targetScreen
        visible: GlobalStates.settingsOpen && root.targetScreen !== null
        color: "transparent"
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
        WlrLayershell.namespace: "ryoku-imi-settings"

        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onPressed: Qt.callLater(() => GlobalStates.settingsOpen = false)
        }

        Item {
            id: plate
            anchors.centerIn: parent
            width: Math.min(980, layer.width - Appearance.spacing.space500 * 2)
            height: Math.min(665, layer.height - Appearance.spacing.space500 * 2)
            focus: true

            Keys.onEscapePressed: GlobalStates.settingsOpen = false
            onFocusChanged: if (focus) Qt.callLater(() => plate.forceActiveFocus())

            StyledRectangularShadow {
                target: backdrop
            }

            Rectangle {
                id: backdrop
                anchors.fill: parent
                radius: Appearance.rounding.windowRounding
                color: Appearance.colors.colLayer0
                border.width: 1
                border.color: Appearance.colors.colOutlineVariant
                clip: true

                MouseArea {
                    anchors.fill: parent
                }

                SettingsContent {
                    anchors.fill: parent
                }

                CloseButton {
                    anchors {
                        top: parent.top
                        right: parent.right
                        margins: Appearance.spacing.space150
                    }
                    onClicked: GlobalStates.settingsOpen = false
                }
            }
        }

        onVisibleChanged: {
            if (visible)
                Qt.callLater(() => plate.forceActiveFocus());
        }
    }
}
