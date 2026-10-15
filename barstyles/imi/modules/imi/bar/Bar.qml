pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import Ryoku.Ui.Singletons
import "../../.."
import "../../../services"
import "../../common"
import "../../common/widgets"

Scope {
    id: bar
    property bool showBarBackground: Config.options.bar.showBackground

    Variants {
        model: {
            const screens = Quickshell.screens;
            const list = Config.options.bar.screenList;
            if (!list || list.length === 0)
                return screens;
            return screens.filter(screen => list.includes(screen.name));
        }
        LazyLoader {
            id: barLoader
            active: GlobalStates.barOpen && !GlobalStates.screenLocked
                && !GlobalStates.editLockPreview
            required property ShellScreen modelData
            component: PanelWindow {
                id: barRoot
                screen: barLoader.modelData

                Timer {
                    id: showBarTimer
                    interval: (Config?.options.bar.autoHide.showWhenPressingSuper.delay ?? 100)
                    repeat: false
                    onTriggered: {
                        barRoot.superShow = true
                    }
                }
                Connections {
                    target: GlobalStates
                    function onSuperDownChanged() {
                        if (!Config?.options.bar.autoHide.showWhenPressingSuper.enable) return;
                        if (GlobalStates.superDown) showBarTimer.restart();
                        else {
                            showBarTimer.stop();
                            barRoot.superShow = false;
                        }
                    }
                }
                property bool superShow: false
                property bool mustShow: hoverRegion.containsMouse || superShow
                    || GlobalStates.editMode
                    || ((GlobalStates.mediaControlsOpen || GlobalStates.sysTrayOverflowOpen) && Config?.options.bar.autoHide.dismissPopups)
                property string screenName: barRoot.screen?.name ?? ""
                property bool monitorHasFullscreen: screenName !== "" && Wm.outputHasFullscreen(screenName)
                property bool monitorHasSpecialOpen: WM.isHyprland && ((HyprlandData.monitors.find(m => m.name === screenName)?.specialWorkspace?.name ?? "") !== "")
                exclusionMode: ExclusionMode.Ignore
                property QtObject barSpaceReserver: BarExclusiveZoneReserver {
                    screen: barLoader.modelData
                    barNamespace: "quickshell:bar"
                    farEdge: Config.options.bar.bottom
                    edgeMargin: Config.options.bar.bottom
                        ? Appearance.sizes.barBottomMargin : Appearance.sizes.barDetachMargin
                    zone: (Config?.options.bar.autoHide.enable && (!barRoot.mustShow || !Config?.options.bar.autoHide.pushWindows))
                        ? 0 : Appearance.sizes.baseBarHeight + (Config.options.bar.cornerStyle === 1 ? Appearance.sizes.hyprlandGapsOut : 0)
                }
                WlrLayershell.namespace: "quickshell:bar"
                WlrLayershell.layer: (monitorHasFullscreen && monitorHasSpecialOpen) ? WlrLayer.Overlay : WlrLayer.Top
                readonly property real detachInset: Appearance.sizes.barDetachInset
                implicitHeight: Appearance.sizes.barSurfaceHeight
                property bool cutOutCornerOpenZones: (monitorHasFullscreen && monitorHasSpecialOpen) && (Config.options.bar.bottom === Config.options.sidebar.cornerOpen.bottom)
                property int cornerOpenCutWidth: cutOutCornerOpenZones ? Config.options.sidebar.cornerOpen.cornerRegionWidth : 0
                property int cornerOpenCutHeight: cutOutCornerOpenZones ? Config.options.sidebar.cornerOpen.cornerRegionHeight : 0
                mask: Region {
                    item: hoverMaskRegion
                    Region {
                        intersection: Intersection.Subtract
                        x: 0
                        y: Config.options.bar.bottom ? (barRoot.height - barRoot.cornerOpenCutHeight) : 0
                        width: barRoot.cornerOpenCutWidth
                        height: barRoot.cornerOpenCutHeight
                    }
                    Region {
                        intersection: Intersection.Subtract
                        x: barRoot.width - barRoot.cornerOpenCutWidth
                        y: Config.options.bar.bottom ? (barRoot.height - barRoot.cornerOpenCutHeight) : 0
                        width: barRoot.cornerOpenCutWidth
                        height: barRoot.cornerOpenCutHeight
                    }
                }
                color: "transparent"

                WindowBlurRegion {
                    targetWindow: barRoot
                    region: Region {
                        Region {
                            item: barContent.backgroundPainted ? barContent.backgroundItem : null
                            radius: barContent.backgroundItem.radius
                        }
                        Region {
                            item: barContent.centerPillPainted ? barContent.centerPillItem : null
                            topLeftRadius: barContent.centerPillItem.topLeftRadius
                            topRightRadius: barContent.centerPillItem.topRightRadius
                            bottomLeftRadius: barContent.centerPillItem.bottomLeftRadius
                            bottomRightRadius: barContent.centerPillItem.bottomRightRadius
                        }
                        Region {
                            item: barContent.materialPillsPainted ? barContent.leftMaterialPillItem : null
                            radius: Math.round(Math.min(barContent.leftMaterialPillItem.width, barContent.leftMaterialPillItem.height) / 2)
                        }
                        Region {
                            item: barContent.materialPillsPainted ? barContent.centerMaterialPillItem : null
                            radius: Math.round(Math.min(barContent.centerMaterialPillItem.width, barContent.centerMaterialPillItem.height) / 2)
                        }
                        Region {
                            item: barContent.materialPillsPainted ? barContent.rightMaterialPillItem : null
                            radius: Math.round(Math.min(barContent.rightMaterialPillItem.width, barContent.rightMaterialPillItem.height) / 2)
                        }
                    }
                }

                anchors {
                    top: !Config.options.bar.bottom
                    bottom: Config.options.bar.bottom
                    left: true
                    right: true
                }

                margins {
                    top: Appearance.sizes.barDetachMargin
                    right: Appearance.sizes.barDeadPixelOverhang
                    bottom: Appearance.sizes.barBottomMargin
                }

                Component.onCompleted: {
                    GlobalFocusGrab.addPersistent(barRoot);
                }
                Component.onDestruction: {
                    GlobalFocusGrab.removePersistent(barRoot);
                }

                DropArea {
                    anchors.fill: parent
                    keys: ["text/uri-list"]
                    onEntered: drag => {
                        if (!Config.options.dropShelf.dragToBarReveal || !drag.hasUrls) {
                            drag.accepted = false
                            return
                        }
                        drag.accepted = true
                        if (!GlobalStates.dropShelfOpen) {
                            GlobalStates.dropShelfX = drag.x
                            GlobalStates.dropShelfAnchorBelow = !Config.options.bar.bottom
                            GlobalStates.dropShelfY = Config.options.bar.bottom
                                ? barRoot.screen.height - Appearance.sizes.barHeight - 10
                                : Appearance.sizes.barHeight
                            GlobalStates.dropShelfOpen = true
                            DropShelf.armAutoDismiss()
                        }
                    }
                    onDropped: drop => {
                        if (!drop.hasUrls) {
                            drop.accepted = false
                            return
                        }
                        DropShelf.addItems(drop.urls)
                        drop.accept()
                    }
                }

                MouseArea  {
                    id: hoverRegion
                    hoverEnabled: true
                    anchors {
                        fill: parent
                        rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * 1
                        bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * 1
                    }

                    Item {
                        id: hoverMaskRegion
                        readonly property real reveal: Config.options.bar.autoHide.hoverRegionWidth
                        readonly property real rawTop: barContent.y - reveal - Appearance.sizes.barDetachInset
                        readonly property real rawBottom: barContent.y + barContent.height + reveal

                        x: 0
                        width: parent.width
                        y: Math.max(0, rawTop)
                        height: Math.max(0, Math.min(parent.height, rawBottom) - y)
                    }

                    RoundCorner {
                        id: leftPillCorner
                        visible: barContent.centerOnly && showBarBackground && Config.options.bar.cornerStyle === 0
                        x: barContent.centerPillX - implicitSize
                        implicitSize: Appearance.rounding.screenRounding
                        color: Appearance.colors.colBarBackground
                        corner: RoundCorner.CornerEnum.TopRight

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: leftPillCorner
                                anchors.top: undefined
                                anchors.bottom: barContent.bottom
                            }
                            PropertyChanges {
                                target: leftPillCorner
                                corner: RoundCorner.CornerEnum.BottomRight
                            }
                        }
                        AnchorChanges {
                            target: leftPillCorner
                            anchors.top: barContent.top
                            anchors.bottom: undefined
                        }
                    }

                    BarContent {
                        id: barContent
                        
                        implicitHeight: Appearance.sizes.barHeight
                        anchors {
                            right: parent.right
                            left: parent.left
                            top: parent.top
                            bottom: undefined
                            topMargin: (Config?.options.bar.autoHide.enable && !mustShow)
                                ? -Appearance.sizes.barHeight : barRoot.detachInset
                            bottomMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.bottom) * -1
                            rightMargin: (Config.options.interactions.deadPixelWorkaround.enable && barRoot.anchors.right) * -1
                        }
                        Behavior on anchors.topMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on anchors.bottomMargin {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: barContent
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: parent.bottom
                                }
                            }
                            PropertyChanges {
                                target: barContent
                                anchors.topMargin: 0
                                anchors.bottomMargin: (Config?.options.bar.autoHide.enable && !mustShow)
                                    ? -Appearance.sizes.barHeight : barRoot.detachInset
                            }
                        }
                    }

                    RoundCorner {
                        id: rightPillCorner
                        visible: barContent.centerOnly && showBarBackground && Config.options.bar.cornerStyle === 0
                        x: barContent.centerPillX + barContent.centerPillWidth
                        implicitSize: Appearance.rounding.screenRounding
                        color: Appearance.colors.colBarBackground
                        corner: RoundCorner.CornerEnum.TopLeft

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: rightPillCorner
                                anchors.top: undefined
                                anchors.bottom: barContent.bottom
                            }
                            PropertyChanges {
                                target: rightPillCorner
                                corner: RoundCorner.CornerEnum.BottomLeft
                            }
                        }
                        AnchorChanges {
                            target: rightPillCorner
                            anchors.top: barContent.top
                            anchors.bottom: undefined
                        }
                    }
                    
                    Loader {
                        id: roundDecorators
                        anchors {
                            left: parent.left
                            right: parent.right
                            top: barContent.bottom
                            bottom: undefined
                        }
                        height: Appearance.rounding.screenRounding
                        active: showBarBackground && Config.options.bar.cornerStyle === 0 && !barContent.centerOnly

                        states: State {
                            name: "bottom"
                            when: Config.options.bar.bottom
                            AnchorChanges {
                                target: roundDecorators
                                anchors {
                                    right: parent.right
                                    left: parent.left
                                    top: undefined
                                    bottom: barContent.top
                                }
                            }
                        }

                        sourceComponent: Item {
                            implicitHeight: Appearance.rounding.screenRounding
                            RoundCorner {
                                id: leftCorner
                                anchors {
                                    top: parent.top
                                    bottom: parent.bottom
                                    left: parent.left
                                }

                                implicitSize: Appearance.rounding.screenRounding
                                color: showBarBackground ? Appearance.colors.colBarBackground : "transparent"

                                corner: RoundCorner.CornerEnum.TopLeft
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        leftCorner.corner: RoundCorner.CornerEnum.BottomLeft
                                    }
                                }
                            }
                            RoundCorner {
                                id: rightCorner
                                anchors {
                                    right: parent.right
                                    top: !Config.options.bar.bottom ? parent.top : undefined
                                    bottom: Config.options.bar.bottom ? parent.bottom : undefined
                                }
                                implicitSize: Appearance.rounding.screenRounding
                                color: showBarBackground ? Appearance.colors.colBarBackground : "transparent"

                                corner: RoundCorner.CornerEnum.TopRight
                                states: State {
                                    name: "bottom"
                                    when: Config.options.bar.bottom
                                    PropertyChanges {
                                        rightCorner.corner: RoundCorner.CornerEnum.BottomRight
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    IpcHandler {
        target: "bar"

        function toggle(): void {
            GlobalStates.barOpen = !GlobalStates.barOpen
        }

        function close(): void {
            GlobalStates.barOpen = false
        }

        function open(): void {
            GlobalStates.barOpen = true
        }
    }

    GlobalShortcut {
        name: "barToggle"
        description: "Toggles bar on press"

        onPressed: {
            GlobalStates.barOpen = !GlobalStates.barOpen;
        }
    }

    GlobalShortcut {
        name: "barOpen"
        description: "Opens bar on press"

        onPressed: {
            GlobalStates.barOpen = true;
        }
    }

    GlobalShortcut {
        name: "barClose"
        description: "Closes bar on press"

        onPressed: {
            GlobalStates.barOpen = false;
        }
    }
}
