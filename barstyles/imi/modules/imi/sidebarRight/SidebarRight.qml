import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"
import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root
    property int sidebarWidth: Appearance.sizes.sidebarWidth
    readonly property bool centerOnly: Config.options.bar.layouts.leftLayout.length === 0 && Config.options.bar.layouts.rightLayout.length === 0 && !Config.options.bar.vertical

    property string targetScreen: ""
    property var activeHost: null

    function latchTarget() {
        root.targetScreen = WM.focusedMonitor?.name ?? "";
    }

    function hostForFocusedMonitor() {
        root.latchTarget();
        const hosts = sidebarWindows.instances;
        return hosts.find(host => host.modelData.name === root.targetScreen) ?? hosts[0] ?? null;
    }

    Component.onCompleted: {
        root.activeHost = root.hostForFocusedMonitor();
    }

    Connections {
        target: GlobalStates
        function onSidebarRightOpenChanged() {
            if (GlobalStates.sidebarRightOpen) {
                root.activeHost = root.hostForFocusedMonitor();
                root.activeHost?.open();
            } else {
                root.activeHost?.close();
            }
        }
    }

    Variants {
        id: sidebarWindows
        model: Quickshell.screens

        Scope {
            id: screenHost
            required property ShellScreen modelData
            readonly property bool isTarget: root.activeHost === screenHost

            property bool panelOpen: false

            function open() {
                screenHost.panelOpen = true;
            }

            function close() {
                screenHost.panelOpen = false;
            }

            PanelWindow {
                id: dismissWindow
                screen: screenHost.modelData
                visible: screenHost.isTarget && screenHost.panelOpen
                color: "transparent"
                exclusionMode: ExclusionMode.Ignore
                exclusiveZone: 0
                anchors {
                    top: true
                    bottom: true
                    left: true
                    right: true
                }
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell:sidebarRightDismiss"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
                mask: Region {
                    width: dismissWindow.width
                    height: dismissWindow.height
                    Region {
                        intersection: Intersection.Subtract
                        x: dismissWindow.width - root.sidebarWidth
                        width: root.sidebarWidth
                        height: dismissWindow.height
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onPressed: Qt.callLater(() => GlobalStates.sidebarRightOpen = false)
                }
            }

            PanelWindow {
                id: panelWindow
                screen: screenHost.modelData

                readonly property EdgeSlide slide: EdgeSlide {
                    open: screenHost.panelOpen
                    travel: entranceWrapper.width
                    direction: 1
                }

                mask: Region {
                    item: (GlobalStates.sidebarRightOpen && screenHost.isTarget) ? entranceWrapper : null
                }

                function hide() {
                    GlobalStates.sidebarRightOpen = false;
                }

                exclusiveZone: 0
                implicitWidth: root.sidebarWidth
                WlrLayershell.namespace: "quickshell:sidebarRight"
                WlrLayershell.keyboardFocus: (GlobalStates.sidebarRightOpen && screenHost.isTarget) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
                color: "transparent"

                anchors {
                    top: true
                    right: true
                    bottom: true
                }

                WindowBlurRegion {
                    targetWindow: panelWindow
                    regionItem: panelWindow.slide.shown ? (sidebarContentLoader.item?.backgroundItem ?? null) : null
                    regionRadius: sidebarContentLoader.item?.backgroundItem?.radius ?? 0
                }

                margins {
                    top: {
                        if (!root.centerOnly) return 0;
                        switch (Config.options.bar.cornerStyle) {
                        case 0: return -Appearance.sizes.barHeight;
                        case 1: return -Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut;
                        case 4: return -Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut;
                        case 2: return -Appearance.sizes.barHeight + Appearance.sizes.hyprlandGapsOut;
                        case 3: return -Appearance.sizes.barHeight - Appearance.sizes.hyprlandGapsOut;
                        default: return 0;
                        }
                    }
                }

                Item {
                    anchors.fill: parent

                    Item {
                        id: entranceWrapper
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: root.sidebarWidth
                        clip: true
                        visible: panelWindow.slide.shown

                        property real cachedParentWidth: root.sidebarWidth
                        readonly property real restX: cachedParentWidth - width
                        x: restX + panelWindow.slide.offset
                        opacity: panelWindow.slide.reveal

                        Connections {
                            target: entranceWrapper.parent
                            function onWidthChanged() {
                                if (entranceWrapper.parent.width > 0)
                                    entranceWrapper.cachedParentWidth = entranceWrapper.parent.width;
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: (mouse) => { mouse.accepted = true }
                            z: -1
                        }

                        Loader {
                            id: sidebarContentLoader
                            active: panelWindow.slide.shown
                                || (Config?.options.sidebar.keepRightSidebarLoaded && screenHost.isTarget)
                            anchors {
                                fill: parent
                                margins: Appearance.sizes.hyprlandGapsOut
                                leftMargin: Appearance.sizes.elevationMargin
                            }
                            width: root.sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
                            height: parent.height - Appearance.sizes.hyprlandGapsOut * 2

                            focus: GlobalStates.sidebarRightOpen && screenHost.isTarget
                            Keys.onPressed: event => {
                                if (event.key === Qt.Key_Escape) {
                                    panelWindow.hide();
                                }
                            }

                            sourceComponent: SidebarRightContent {}
                        }
                    }
                }
            }
        }
    }
}
