import "../../.."
import "../../../services"
import ".."
import "."
import "../functions"
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import "../functions/edit_mode.js" as EditMode
import Quickshell.Io
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland
import "../../imi/dock/dock_geometry.js" as DockGeometry
import "../functions/layout_ops.js" as LayoutOps

Item {
    id: root

    readonly property string dockEdge: DockGeometry.normalizedEdge(
        Config.options?.dock.edge ?? "bottom")
    readonly property bool vertical: DockGeometry.isVertical(root.dockEdge)

    property real btnSize: 46
    property real btnSpacing: Appearance.spacing.space25
    property real buttonPadding: Appearance.spacing.space50
    property var pinnedApps: Config.options?.dock.pinnedApps ?? []
    property real maxWindowPreviewHeight: 200
    property real maxWindowPreviewWidth: 300
    property real windowControlsHeight: 30
    property Item lastHoveredButton: null
    property bool buttonHovered: false
    property var contextMenu: null
    property bool requestDockShow: previewPopup.show
    signal orderChanged(var newOrder)
    property var  _workOrder: pinnedApps.slice()
    property int  activeDragVisualIndex: -1
    property bool _dragging: false

    onPinnedAppsChanged: {
        if (!_dragging) {
            _workOrder = pinnedApps.slice()
        }
    }

    readonly property real slotRun: _workOrder.length * btnSize
        + Math.max(0, _workOrder.length - 1) * btnSpacing
    implicitWidth:  root.vertical ? (parent?.width ?? btnSize) : slotRun
    implicitHeight: root.vertical ? slotRun : (parent?.height ?? btnSize)

    function popupCenterForButton(button) {
        if (!button || !root.QsWindow) return 0
        const centre = root.QsWindow.mapFromItem(button, button.width / 2, button.height / 2)
        return root.vertical ? centre.y : centre.x
    }

    function moveSlot(fromPos, toPos) {
        root._workOrder = LayoutOps.move(root._workOrder, fromPos, toPos)
    }

    function commitOrder() {
        const newOrder = _workOrder.slice()
        const before = EditMode.listCopy(Config.options.dock.pinnedApps)
        let changed = before.length !== newOrder.length
        for (let i = 0; !changed && i < newOrder.length; i++)
            changed = before[i] !== newOrder[i]
        if (changed)
            GlobalStates.editUndoPush(() => {
                Config.options.dock.pinnedApps = before
            })
        Config.options.dock.pinnedApps = newOrder
        orderChanged(newOrder)
    }

    Repeater {
        id: slotRepeater
        model: root._workOrder.length

        delegate: Item {
            id: slotItem
            required property int index

            property string appId:     root._workOrder[index] ?? ""
            property var    appEntry:  TaskbarApps.apps.find(a => a.appId === appId) ?? null
            property var    deskEntry: liveDeskEntry.entry
            property bool   appActive: appEntry?.toplevels?.find(t => t.activated) !== undefined
            property int    _lastFocused: -1

            LiveDesktopEntry {
                id: liveDeskEntry
                appId: slotItem.appId
            }

            readonly property real slotOffset: index * (root.btnSize + root.btnSpacing)
            width:  root.vertical ? root.implicitWidth : root.btnSize
            height: root.vertical ? root.btnSize : root.implicitHeight
            x:      root.vertical ? 0 : slotOffset
            y:      root.vertical ? slotOffset : 0

            Behavior on x {
                enabled: root.activeDragVisualIndex !== slotItem.index
                animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
            }
            Behavior on y {
                enabled: root.activeDragVisualIndex !== slotItem.index
                animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
            }

            opacity: (root.activeDragVisualIndex === index) ? 0.0 : 1.0
            scale:   (root.activeDragVisualIndex === index) ? 0.7 : 1.0
            Behavior on opacity { NumberAnimation { duration: Appearance.animation.elementMoveFaster.duration; easing.type: Easing.OutCubic } }
            Behavior on scale   { NumberAnimation { duration: Appearance.animation.elementMoveFaster.duration; easing.type: Easing.OutCubic } }

            Item {
                visible: dragHandler.active
                z: 1000
                width:  root.btnSize
                height: root.btnSize
                readonly property point localPointer: dragHandler.active
                    ? slotItem.mapFromItem(null,
                        dragHandler.centroid.scenePosition.x,
                        dragHandler.centroid.scenePosition.y)
                    : Qt.point(0, 0)
                x: root.vertical
                    ? (slotItem.width - width) / 2
                    : (dragHandler.active ? localPointer.x - width / 2 : 0)
                y: root.vertical
                    ? (dragHandler.active ? localPointer.y - height / 2 : 0)
                    : (slotItem.height - height) / 2

                scale: dragHandler.active ? 1.15 : 0.9
                Behavior on scale {
                    NumberAnimation { duration: 220; easing.type: Easing.OutBack; easing.overshoot: 2.2 }
                }

                IconImage {
                    id: ghostIcon
                    anchors.centerIn: parent
                    source: Quickshell.iconPath(
                        AppSearch.guessIcon(root._workOrder[root.activeDragVisualIndex] ?? ""),
                        "image-missing")
                    implicitSize: root.btnSize * 0.65
                    opacity: 0.85

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowVerticalOffset: dragHandler.active ? 7 : 4
                        shadowBlur: dragHandler.active ? 0.85 : 0.65
                        shadowColor: "#80000000"

                        Behavior on shadowVerticalOffset { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                        Behavior on shadowBlur { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    }
                }
            }

            DockButton {
                id: dockBtn
                anchors.fill: parent

                property var appToplevel: slotItem.appEntry

                insetInward:  Appearance.sizes.hyprlandGapsOut + Appearance.spacing.space100
                insetOutward: Appearance.sizes.hyprlandGapsOut + Appearance.spacing.space100

                hoverEnabled: true
                onHoveredChanged: {
                    if (hovered) {
                        root.lastHoveredButton = dockBtn
                        root.buttonHovered = true
                    } else {
                        root.buttonHovered = false
                    }
                }

                onClicked: {
                    const entry = slotItem.appEntry
                    if (!entry || entry.toplevels.length === 0) {
                        DockLaunchTracker.markLaunching(slotItem.appId)
                        AppUsage.recordLaunch(slotItem.deskEntry?.id)
                        slotItem.deskEntry?.execute()
                        return
                    }
                    const next = (slotItem._lastFocused + 1) % entry.toplevels.length
                    slotItem._lastFocused = next
                    entry.toplevels[next].activate()
                }

                middleClickAction: () => {
                    DockLaunchTracker.markLaunching(slotItem.appId)
                    AppUsage.recordLaunch(slotItem.deskEntry?.id)
                    slotItem.deskEntry?.execute()
                }
                altAction:         () => {
                    if (root._dragging) return
                    if (root.contextMenu) {
                        root.contextMenu.open(dockBtn, slotItem.appEntry, slotItem.appId)
                    } else {
                        TaskbarApps.togglePin(slotItem.appId)
                    }
                }

                contentItem: DockIconMotion {
                    id: pinnedIconMotion
                    anchors.fill: parent
                    hovered: dockBtn.hovered
                    pressed: dockBtn.down
                    dragging: root._dragging
                    launching: DockLaunchTracker.isLaunching(slotItem.appId)

                    Component.onCompleted: {
                        if (DockLaunchTracker.firstAppearance(slotItem.appId))
                            playAppear();
                    }

                    Item {
                        anchors.centerIn: parent
                        width: 33
                        height: 33

                        IconImage {
                            id: appIcon
                            anchors.centerIn: parent
                            source: Quickshell.iconPath(
                                AppSearch.guessIcon(slotItem.appId),
                                "image-missing")
                            implicitSize: 33
                        }

                        Loader {
                            active: Config.options.dock.monochromeIcons
                            anchors.fill: appIcon
                            sourceComponent: Item {
                                Desaturate {
                                    id: desaturatedIcon
                                    visible: false
                                    anchors.fill: parent
                                    source: appIcon
                                    desaturation: 0.8
                                }
                                ColorOverlay {
                                    anchors.fill: desaturatedIcon
                                    source: desaturatedIcon
                                    color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.9)
                                }
                            }
                        }

                        Flow {
                            spacing: Appearance.spacing.space50
                            readonly property string dotSide: DockGeometry.outwardSide(root.dockEdge)
                            flow: root.vertical ? Flow.TopToBottom : Flow.LeftToRight
                            readonly property real dotPushX:
                                (appIcon.width + width) / 2 + Appearance.spacing.space25
                            readonly property real dotPushY:
                                (appIcon.height + height) / 2 + Appearance.spacing.space25
                            anchors.centerIn: parent
                            anchors.horizontalCenterOffset: dotSide === "right" ? dotPushX
                                : (dotSide === "left" ? -dotPushX : 0)
                            anchors.verticalCenterOffset: dotSide === "bottom" ? dotPushY
                                : (dotSide === "top" ? -dotPushY : 0)
                            Repeater {
                                model: Math.min(slotItem.appEntry?.toplevels?.length ?? 0, 3)
                                delegate: Rectangle {
                                    required property int index
                                    readonly property real pillLength:
                                        (slotItem.appEntry?.toplevels?.length ?? 0) <= 3 ? 10 : 4
                                    radius:         Appearance.rounding.full
                                    implicitWidth:  root.vertical ? 4 : pillLength
                                    implicitHeight: root.vertical ? pillLength : 4
                                    color: slotItem.appActive
                                           ? Appearance.colors.colPrimary
                                           : ColorUtils.transparentize(Appearance.colors.colOnLayer0, 0.4)
                                    Behavior on implicitWidth {
                                        animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                                    }
                                    Behavior on implicitHeight {
                                        animation: Appearance.animation.elementMoveSmall.numberAnimation.createObject(this)
                                    }
                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Loader {
                anchors.fill: parent
                z: 500
                active: GlobalStates.editMode
                sourceComponent: Item {
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.AllButtons
                        hoverEnabled: true
                        onWheel: wheel => {
                            wheel.accepted = true;
                        }
                    }
                    EditRemoveBadge {
                        objectName: "dockEditRemove"
                        anchors.top: parent.top
                        anchors.right: parent.right
                        onClicked: {
                            if (!GlobalStates.editMode || root._dragging) return;
                            const beforePins = EditMode.listCopy(Config.options.dock.pinnedApps);
                            GlobalStates.editUndoPush(() => {
                                Config.options.dock.pinnedApps = beforePins;
                            });
                            Config.options.dock.pinnedApps =
                                LayoutOps.remove(root.pinnedApps, slotItem.index);
                        }
                    }
                }
            }

            DragHandler {
                id: dragHandler
                target: null
                grabPermissions: PointerHandler.CanTakeOverFromAnything

                onActiveChanged: {
                    if (active) {
                        root._dragging = true
                        root.activeDragVisualIndex = index
                        root.buttonHovered = false
                        return
                    }
                    root.activeDragVisualIndex = -1
                    root._dragging = false
                    root.commitOrder()
                }

                readonly property string axis: root.vertical ? "y" : "x"
                function alongAxis(point) {
                    return point[axis]
                }

                function slotCentres(skipIndex) {
                    const centres = []
                    for (let i = 0; i < slotRepeater.count; i++) {
                        const child = i === skipIndex ? null : slotRepeater.itemAt(i)
                        centres.push(child
                            ? child.mapToItem(null, child.width / 2, child.height / 2)
                            : null)
                    }
                    return centres
                }

                onCentroidChanged: {
                    if (!active) return
                    const currentVisualIdx = root.activeDragVisualIndex
                    if (currentVisualIdx < 0) return

                    const dragPos = alongAxis(dragHandler.centroid.scenePosition)
                    const centres = slotCentres(currentVisualIdx)
                    const nearestIdx = LayoutOps.indexAt(
                        centres, dragHandler.centroid.scenePosition, axis)
                    if (nearestIdx === -1 || nearestIdx === currentVisualIdx) return

                    const nc = alongAxis(centres[nearestIdx])
                    const crossed = (nearestIdx > currentVisualIdx)
                        ? (dragPos >= nc)
                        : (dragPos <= nc)

                    if (crossed) {
                        root.moveSlot(currentVisualIdx, nearestIdx)
                        root.activeDragVisualIndex = nearestIdx
                    }
                }
            }
        }
    }

    PopupWindow {
        id: previewPopup
        property var appTopLevel: root.lastHoveredButton?.appToplevel ?? null

        property bool shouldShow: (popupMouseArea.containsMouse || root.buttonHovered)
                                  && !root._dragging
                                  && !GlobalStates.editMode
                                  && !(root.contextMenu?.isOpen ?? false)
                                  && appTopLevel
                                  && appTopLevel.toplevels
                                  && appTopLevel.toplevels.length > 0

        property bool show: false
        property real cachedCenter: 0

        Connections {
            target: root
            function onLastHoveredButtonChanged() {
                if (root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenter = root.popupCenterForButton(root.lastHoveredButton)
            }
            function onButtonHoveredChanged() {
                if (root.buttonHovered && root.lastHoveredButton && root.QsWindow)
                    previewPopup.cachedCenter = root.popupCenterForButton(root.lastHoveredButton)
                updateTimer.restart()
            }
        }

        onShouldShowChanged: {
            updateTimer.restart()
        }

        Timer {
            id: updateTimer
            interval: 100
            onTriggered: {
                previewPopup.show = previewPopup.shouldShow
            }
        }

        readonly property var anchorSides: DockGeometry.popupAnchorSides(root.dockEdge)
        function edgeFlags(names) {
            let flags = 0
            for (const name of names) {
                flags |= name === "top" ? Edges.Top
                    : name === "bottom" ? Edges.Bottom
                    : name === "left" ? Edges.Left : Edges.Right
            }
            return flags
        }

        anchor {
            window: root.QsWindow.window
            rect: Qt.rect(0, 0,
                root.QsWindow.window?.width ?? 0,
                root.QsWindow.window?.height ?? 0)
            adjustment: PopupAdjustment.None
            gravity: previewPopup.edgeFlags(previewPopup.anchorSides.gravity)
            edges: previewPopup.edgeFlags(previewPopup.anchorSides.edges)
        }

        visible: popupBackground.opacity > 0
        color: "transparent"
        implicitWidth: root.vertical
            ? popupMouseArea.implicitWidth + Appearance.sizes.elevationMargin * 2
            : (root.QsWindow.window?.width ?? 1)
        implicitHeight: root.vertical
            ? (root.QsWindow.window?.height ?? 1)
            : popupMouseArea.implicitHeight
                + root.windowControlsHeight
                + Appearance.sizes.elevationMargin * 2

        MouseArea {
            id: popupMouseArea
            readonly property string dockSide: DockGeometry.outwardSide(root.dockEdge)
            implicitWidth:  popupBackground.implicitWidth + Appearance.sizes.elevationMargin * 2
            implicitHeight: root.maxWindowPreviewHeight
                            + root.windowControlsHeight
                            + Appearance.sizes.elevationMargin * 2
            hoverEnabled: true
            readonly property real acrossX: dockSide === "right" ? parent.width - width : 0
            readonly property real acrossY: dockSide === "bottom" ? parent.height - height : 0
            x: root.vertical ? acrossX : previewPopup.cachedCenter - width / 2
            y: root.vertical ? previewPopup.cachedCenter - height / 2 : acrossY

            StyledRectangularShadow {
                target: popupBackground
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
            }

            Rectangle {
                id: popupBackground
                property real padding: Appearance.spacing.space100
                opacity: previewPopup.show ? 1 : 0
                visible: opacity > 0
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                clip: true
                color: Appearance.m3colors.m3surfaceContainer
                radius: Appearance.rounding.normal
                readonly property real cardPushX:
                    (parent.width - width) / 2 - Appearance.sizes.elevationMargin
                readonly property real cardPushY:
                    (parent.height - height) / 2 - Appearance.sizes.elevationMargin
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: popupMouseArea.dockSide === "right" ? cardPushX
                    : (popupMouseArea.dockSide === "left" ? -cardPushX : 0)
                anchors.verticalCenterOffset: popupMouseArea.dockSide === "bottom" ? cardPushY
                    : (popupMouseArea.dockSide === "top" ? -cardPushY : 0)
                implicitHeight: previewRowLayout.implicitHeight + padding * 2
                implicitWidth:  previewRowLayout.implicitWidth  + padding * 2
                Behavior on implicitWidth {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on implicitHeight {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                RowLayout {
                    id: previewRowLayout
                    anchors.centerIn: parent

                    Repeater {
                        model: ScriptModel {
                            values: previewPopup.appTopLevel?.toplevels ?? []
                        }

                        RippleButton {
                            id: windowButton
                            Layout.fillHeight: true
                            required property var modelData
                            padding: 0

                            middleClickAction: () => { windowButton.modelData?.close() }
                            onClicked: { windowButton.modelData?.activate() }

                            contentItem: ColumnLayout {
                                implicitWidth:  screencopyView.implicitWidth
                                implicitHeight: screencopyView.implicitHeight

                                ButtonGroup {
                                    contentWidth: parent.width - anchors.margins * 2

                                    MarqueeText {
                                        Layout.margins: Appearance.spacing.space100
                                        Layout.fillWidth: true
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        text: windowButton.modelData?.title ?? ""
                                        color: Appearance.m3colors.m3onSurface
                                    }

                                    GroupButton {
                                        id: closeButton
                                        colBackground: ColorUtils.transparentize(
                                            Appearance.colors.colSurfaceContainer)
                                        baseWidth:    root.windowControlsHeight
                                        baseHeight:   root.windowControlsHeight
                                        buttonRadius: Appearance.rounding.full
                                        contentItem: MaterialSymbol {
                                            anchors.centerIn: parent
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "close"
                                            iconSize: Appearance.font.pixelSize.normal
                                            color: Appearance.m3colors.m3onSurface
                                        }
                                        onClicked: { windowButton.modelData?.close() }
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    implicitHeight: screencopyView.height
                                    implicitWidth:  screencopyView.width

                                    ScreencopyView {
                                        id: screencopyView
                                        anchors.centerIn: parent
                                        captureSource: windowButton.modelData
                                        live: true
                                        paintCursor: true
                                        constraintSize: Qt.size(
                                            root.maxWindowPreviewWidth,
                                            root.maxWindowPreviewHeight)
                                        layer.enabled: true
                                        layer.effect: OpacityMask {
                                            maskSource: Rectangle {
                                                width:  screencopyView.width
                                                height: screencopyView.height
                                                radius: Appearance.rounding.small
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
