import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../.."
import "../../common"
import "../../common/plugins"

Scope {
    id: root

    Loader {
        active: GlobalStates.editWidgetMenuOpen
        sourceComponent: PanelWindow {
            id: menuWindow

            screen: Quickshell.screens.find(
                candidate => candidate.name === GlobalStates.editWidgetMenuScreenName)
                ?? Quickshell.screens[0]

            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            exclusiveZone: 0
            WlrLayershell.namespace: "quickshell:desktopMenu"
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                onClicked: GlobalStates.editWidgetMenuOpen = false
            }

            MouseArea {
                x: card.x
                y: card.y
                width: card.width
                height: card.height
                acceptedButtons: Qt.AllButtons
            }

            EditWidgetMenuContent {
                id: card
                manifest: PluginManager.availablePlugins.find(
                    entry => entry.id === GlobalStates.editWidgetMenuPluginId) ?? null
                screenName: menuWindow.screen?.name ?? ""
                width: implicitWidth
                height: implicitHeight
                x: Math.min(Math.max(GlobalStates.editWidgetMenuX, 8),
                    menuWindow.width - width - 8)
                y: Math.min(Math.max(GlobalStates.editWidgetMenuY, 8),
                    menuWindow.height - height - 8)
                onDismissRequested: GlobalStates.editWidgetMenuOpen = false

                scale: 0.85
                opacity: 0
                transformOrigin: Item.TopLeft
                Component.onCompleted: {
                    scale = 1.0;
                    opacity = 1.0;
                }
                Behavior on scale {
                    animation: Appearance.animation.elementMoveEnter.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }
        }
    }
}
