import QtQuick
import QtQuick.Window
import Qt5Compat.GraphicalEffects
import Quickshell
import "../../.."
import "../../../services"
import ".."
import "../widgets"
import "../../.."
import "../functions/parallax.js" as ParallaxMath
import "../functions/edit_mode.js" as EditMode
import "gridSizes.js" as GridSizes
import "resize-tension.js" as Tension
import "gridResize.js" as GridResize

AbstractBackgroundWidget {
    id: rootWidget
    required property var manifest
    required property string screenName

    property bool wallpaperSafetyTriggered: false

    visibleWhenLocked: Config.options.lock.showWidgets
        ? PluginState.lockWidgetEnabled(rootWidget.manifest?.id ?? "")
        : pluginNode.wantsVisibleWhenLocked
    readonly property bool lockOnlyWidget: Config.options.lock.showWidgets
        && PluginState.lockWidgetEnabled(rootWidget.manifest?.id ?? "")
        && !Config.options.plugins.enabled.includes(rootWidget.manifest?.id ?? "")
    visibleOnDesktop: !rootWidget.lockOnlyWidget
    readonly property bool forceCenter: pluginNode.wantsForceCenter

    needsColText: pluginNode.wantsAdaptiveTextColor
    onNeedsColTextChanged: rootWidget.refreshPlacementIfNeeded()

    property Item weSurfaceItem: null

    property real canvasOffsetX: 0
    property real canvasOffsetY: 0
    property rect wallpaperRect: Qt.rect(0, 0, 0, 0)

    readonly property var frostSampleOrigin: ParallaxMath.sampleOrigin(
        { x: rootWidget.canvasOffsetX, y: rootWidget.canvasOffsetY },
        { x: rootWidget.x, y: rootWidget.y },
        { x: rootWidget.wallpaperRect.x, y: rootWidget.wallpaperRect.y })

    readonly property bool blurEnabled: manifest
        ? PluginState.option(manifest.id, "blurEnabled", manifest.desktopWidget?.blur === true)
        : false

    positionLocked: manifest
        ? PluginState.option(manifest.id, "positionLocked", manifest.desktopWidget?.locked === true)
        : false
    clickThrough: manifest
        ? PluginState.option(manifest.id, "clickThrough", manifest.desktopWidget?.clickThrough === true)
        : false
    readonly property bool keepTranslucent: manifest
        ? PluginState.option(manifest.id, "keepTranslucent", manifest.desktopWidget?.keepTranslucent === true)
        : false
    readonly property bool followParallax: manifest
        ? PluginState.option(manifest.id, "followParallax", manifest.desktopWidget?.followParallax !== false)
        : true
    readonly property bool frostBlur: Config.options.plugins.frostMode === "blur"
    readonly property bool liveWallpaperActive: rootWidget.weSurfaceItem !== null
    readonly property bool hasBlurSurface: !pluginNode.hasCustomBlurRegions
        || pluginNode.blurRegions.length > 0

    readonly property real widgetRounding: {
        const val = manifest?.desktopWidget?.props?.radius;
        if (typeof val === "string" && val.startsWith("Appearance.rounding.")) {
            return Appearance.rounding[val.substring(20)] ?? Appearance.rounding.large;
        }
        if (typeof val === "number") return val;
        return Appearance.rounding.large;
    }

    readonly property var gridSpec: (manifest && manifest.grid) ? manifest.grid : null
    readonly property var offeredGridSizes: GridSizes.offeredSizes(rootWidget.gridSpec)
    readonly property bool gridResizable: rootWidget.offeredGridSizes.length > 1
    readonly property var storedGridSize: GridSizes.resolveSize(rootWidget.gridSpec,
        manifest ? PluginState.gridSize(manifest.id, screenName) : undefined)
    property var previewGridSize: null
    readonly property bool resizingGrid: previewGridSize !== null
    readonly property var gridSize: previewGridSize ?? storedGridSize
    readonly property bool gridSized: rootWidget.gridSize !== null && rootWidget.gridSize !== undefined
    readonly property int gridCols: gridSize ? gridSize.cols : 0
    readonly property int gridRows: gridSize ? gridSize.rows : 0
    readonly property real gridSpanWidth: gridSize ? Appearance.sizes.widgetGridSpanX(gridCols) : 0
    readonly property real gridSpanHeight: gridSize ? Appearance.sizes.widgetGridSpanY(gridRows) : 0

    readonly property bool gridResizeAnimated: rootWidget.gridSized && PluginState.ready
    readonly property int gridResizeDuration: GridResize.resizeDurationMs(
        rootWidget.resizingGrid,
        Appearance.animation.elementMoveSmall.duration,
        Appearance.animation.elementMove.duration)
    readonly property var gridResizeCurve: rootWidget.resizingGrid
        ? Appearance.animationCurves.expressiveFastSpatial
        : Appearance.animationCurves.expressiveDefaultSpatial

    readonly property bool boxInMotion: rootWidget.resizingGrid
        || Math.abs(rootWidget.width - rootWidget.settledWidth) > 0.5
        || Math.abs(rootWidget.height - rootWidget.settledHeight) > 0.5

    Behavior on width {
        enabled: rootWidget.gridResizeAnimated
        NumberAnimation {
            duration: rootWidget.gridResizeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: rootWidget.gridResizeCurve
        }
    }
    Behavior on height {
        enabled: rootWidget.gridResizeAnimated
        NumberAnimation {
            duration: rootWidget.gridResizeDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: rootWidget.gridResizeCurve
        }
    }

    readonly property string targetGridSpan: GridSizes.formatSize(rootWidget.gridSize)
    property string shownGridSpan: ""

    onTargetGridSpanChanged: {
        if (pluginNode.wantsOwnSpanTransition) {
            spanSwap.stop();
            pluginNode.opacity = 1;
            rootWidget.shownGridSpan = rootWidget.targetGridSpan;
            return;
        }
        if (!rootWidget.gridResizeAnimated
                || !GridResize.animatesSpanSwap(rootWidget.shownGridSpan, rootWidget.targetGridSpan)) {
            spanSwap.stop();
            pluginNode.opacity = 1;
            rootWidget.shownGridSpan = rootWidget.targetGridSpan;
            return;
        }
        spanSwap.restart();
    }

    SequentialAnimation {
        id: spanSwap
        Component.onCompleted: rootWidget.shownGridSpan = rootWidget.targetGridSpan
        NumberAnimation {
            target: pluginNode
            property: "opacity"
            to: 0
            duration: GridResize.contentSwapHalfMs(rootWidget.gridResizeDuration)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        ScriptAction { script: rootWidget.shownGridSpan = rootWidget.targetGridSpan }
        NumberAnimation {
            target: pluginNode
            property: "opacity"
            to: 1
            duration: GridResize.contentSwapHalfMs(rootWidget.gridResizeDuration)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
    }

    readonly property real settledWidth: rootWidget.gridSized ? rootWidget.gridSpanWidth : rootWidget.width
    readonly property real settledHeight: rootWidget.gridSized ? rootWidget.gridSpanHeight : rootWidget.height
    clampWidth: rootWidget.settledWidth
    clampHeight: rootWidget.settledHeight

    function commitGridSize(size) {
        if (!manifest || !size) return;
        const id = manifest.id;
        const screen = rootWidget.screenName;
        const surface = PluginState.currentSurface;
        const next = GridSizes.formatSize(size);
        const before = PluginState.gridSize(id, screen, surface) ?? null;
        if (before !== next)
            GlobalStates.editUndoPush(() => PluginState.setGridSize(id, screen, before, surface));
        PluginState.setGridSize(id, screen, next, surface);
    }

    function beginGridResize() {
        rootWidget.previewGridSize = rootWidget.storedGridSize;
    }

    property real resizePullX: 0
    property real resizePullY: 0
    readonly property point resizeBow: Qt.point(
        rootWidget.resizingGrid ? Tension.bow(rootWidget.resizePullX) : 0,
        rootWidget.resizingGrid ? Tension.bow(rootWidget.resizePullY) : 0)

    function previewGridResize(targetWidth, targetHeight) {
        if (!rootWidget.resizingGrid) return;
        let current = rootWidget.previewGridSize;
        for (;;) {
            const edge = Appearance.sizes.widgetGridSpanX(current.cols);
            if (targetWidth > edge + Tension.BREAK_PX) {
                const up = Tension.stepSize(rootWidget.offeredGridSizes, current, 1, 0);
                if (up === current) break;
                current = up;
                continue;
            }
            const down = Tension.stepSize(rootWidget.offeredGridSizes, current, -1, 0);
            if (down !== current
                    && targetWidth < Appearance.sizes.widgetGridSpanX(down.cols)) {
                current = down;
                continue;
            }
            break;
        }
        for (;;) {
            const edge = Appearance.sizes.widgetGridSpanY(current.rows);
            if (targetHeight > edge + Tension.BREAK_PX) {
                const up = Tension.stepSize(rootWidget.offeredGridSizes, current, 0, 1);
                if (up === current) break;
                current = up;
                continue;
            }
            const down = Tension.stepSize(rootWidget.offeredGridSizes, current, 0, -1);
            if (down !== current
                    && targetHeight < Appearance.sizes.widgetGridSpanY(down.rows)) {
                current = down;
                continue;
            }
            break;
        }
        rootWidget.previewGridSize = current;
        rootWidget.resizePullX = Math.max(-Tension.BREAK_PX, Math.min(Tension.BREAK_PX,
            targetWidth - Appearance.sizes.widgetGridSpanX(current.cols)));
        rootWidget.resizePullY = Math.max(-Tension.BREAK_PX, Math.min(Tension.BREAK_PX,
            targetHeight - Appearance.sizes.widgetGridSpanY(current.rows)));
    }

    function endGridResize() {
        const chosen = rootWidget.previewGridSize;
        rootWidget.previewGridSize = null;
        rootWidget.resizePullX = 0;
        rootWidget.resizePullY = 0;
        rootWidget.commitGridSize(chosen);
    }

    function cancelGridResize() {
        rootWidget.previewGridSize = null;
        rootWidget.resizePullX = 0;
        rootWidget.resizePullY = 0;
    }

    onContextMenuRequested: (atX, atY) => {
        if (!manifest) return;
        const point = rootWidget.mapToItem(null, atX, atY);
        GlobalStates.editWidgetMenuPluginId = manifest.id;
        GlobalStates.editWidgetMenuScreenName = rootWidget.screenName;
        GlobalStates.editWidgetMenuX = point.x;
        GlobalStates.editWidgetMenuY = point.y;
        GlobalStates.editWidgetMenuOpen = true;
    }

    readonly property var editDrawerReveal:
        GlobalStates.editDrawerReveals[rootWidget.screenName] ?? null

    function dropWouldRemoveAt(screenX, screenY) {
        if (!GlobalStates.editMode || !GlobalStates.editDrawerOpen || !manifest)
            return false;
        if (!Config.options.plugins.enabled.includes(manifest.id))
            return false;
        return EditMode.pointInDrawerReveal(rootWidget.editDrawerReveal,
            screenX, screenY);
    }

    onPositionChanged: {
        if (!rootWidget.dragging) return;
        const point = rootWidget.parent.mapToItem(null,
            rootWidget.dragPointerParentX, rootWidget.dragPointerParentY);
        GlobalStates.editDrawerDropScreen =
            rootWidget.dropWouldRemoveAt(point.x, point.y)
                ? rootWidget.screenName : "";
    }

    function releaseRemovesWidget(mouseX, mouseY) {
        const point = rootWidget.mapToItem(null, mouseX, mouseY);
        if (!rootWidget.dropWouldRemoveAt(point.x, point.y)) return false;
        rootWidget.restoreXYBinding();
        GlobalStates.editWidgetDroppedOnDrawer(manifest.id);
        return true;
    }

    onDraggingChanged: {
        if (!rootWidget.dragging)
            GlobalStates.editDrawerDropScreen = "";
    }

    Component.onDestruction: {
        if (manifest && GlobalStates.editWidgetMenuOpen
                && GlobalStates.editWidgetMenuPluginId === manifest.id
                && GlobalStates.editWidgetMenuScreenName === rootWidget.screenName)
            GlobalStates.editWidgetMenuOpen = false;
    }

    configEntryName: manifest ? "plugin_" + manifest.id : "plugin_unknown"

    hoverEnabled: true
    keyboardFocusRequested: rootWidget.containsMouse || rootWidget.descendantHasFocus
    readonly property bool descendantHasFocus: {
        let focusItem = rootWidget.Window.activeFocusItem;
        while (focusItem) {
            if (focusItem === rootWidget) return true;
            focusItem = focusItem.parent;
        }
        return false;
    }

    property var currentConfig: manifest
        ? PluginState.position(manifest.id, screenName)
        : PluginState.defaultPosition()
    placementStrategy: currentConfig.placementStrategy || "free"

    function applyPersistedPosition() {
        const nextX = currentConfig.x !== undefined ? currentConfig.x : 100;
        const nextY = currentConfig.y !== undefined ? currentConfig.y : 100;
        rootWidget.targetX = rootWidget.clampX(nextX);
        rootWidget.targetY = rootWidget.clampY(nextY);
    }

    onCurrentConfigChanged: applyPersistedPosition()
    Component.onCompleted: applyPersistedPosition()

    readonly property string storedGridSpan: GridSizes.formatSize(rootWidget.storedGridSize)
    onStoredGridSpanChanged: storedSpanRepair.restart()

    Timer {
        id: storedSpanRepair
        interval: 0
        onTriggered: rootWidget.repairUnreachableStoredPosition()
    }

    function repairUnreachableStoredPosition() {
        if (!manifest || !PluginState.ready) return;
        if (rootWidget.settledWidth <= 0 || rootWidget.scaledScreenWidth <= 0) return;
        const stored = rootWidget.currentConfig;
        const nextX = rootWidget.clampX(stored.x);
        const nextY = rootWidget.clampY(stored.y);
        if (nextX === stored.x && nextY === stored.y) return;
        PluginState.setPosition(manifest.id, screenName, {
            x: nextX,
            y: nextY,
            placementStrategy: rootWidget.placementStrategy
        });
    }

    Timer {
        id: storedPositionRepair
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            if (!PluginState.ready || rootWidget.width <= 0 || rootWidget.height <= 0)
                return;
            storedPositionRepair.running = false;
            rootWidget.repairUnreachableStoredPosition();
        }
    }

    readonly property real placedX: rootWidget.forceCenter
        ? ((scaledScreenWidth - width) / 2) : targetX
    readonly property real placedY: rootWidget.forceCenter
        ? ((scaledScreenHeight - height) / 2) : targetY

    readonly property Item parallaxCanvas: rootWidget.findCanvas(rootWidget.parent)
    readonly property real parallaxCancelX: ParallaxMath.parallaxCancel(
        rootWidget.parallaxCanvas ? rootWidget.parallaxCanvas.x : 0, rootWidget.followParallax)
    readonly property real parallaxCancelY: ParallaxMath.parallaxCancel(
        rootWidget.parallaxCanvas ? rootWidget.parallaxCanvas.y : 0, rootWidget.followParallax)

    animatePosition: rootWidget.followParallax

    snapOffsetX: rootWidget.parallaxCancelX
    snapOffsetY: rootWidget.parallaxCancelY

    x: ParallaxMath.drawnFromPlacement(rootWidget.placedX, rootWidget.parallaxCancelX)
    y: ParallaxMath.drawnFromPlacement(rootWidget.placedY, rootWidget.parallaxCancelY)

    function restoreXYBinding() {
        rootWidget.x = Qt.binding(() => ParallaxMath.drawnFromPlacement(
            rootWidget.placedX, rootWidget.parallaxCancelX));
        rootWidget.y = Qt.binding(() => ParallaxMath.drawnFromPlacement(
            rootWidget.placedY, rootWidget.parallaxCancelY));
    }

    function commitPosition() {
        const beforeX = rootWidget.targetX;
        const beforeY = rootWidget.targetY;
        rootWidget.targetX = rootWidget.clampX(ParallaxMath.placementFromDrawn(
            rootWidget.x, rootWidget.parallaxCancelX));
        rootWidget.targetY = rootWidget.clampY(ParallaxMath.placementFromDrawn(
            rootWidget.y, rootWidget.parallaxCancelY));
        rootWidget.restoreXYBinding();
        rootWidget.commitPlacement(beforeX, beforeY);
    }

    function commitPlacement(beforeX, beforeY) {
        if (!manifest) return;
        const id = manifest.id;
        const screen = rootWidget.screenName;
        const surface = PluginState.currentSurface;
        if (beforeX !== rootWidget.targetX || beforeY !== rootWidget.targetY) {
            const before = {
                x: beforeX,
                y: beforeY,
                placementStrategy: rootWidget.placementStrategy
            };
            GlobalStates.editUndoPush(() => PluginState.setPosition(id, screen, before, surface));
        }
        PluginState.setPosition(id, screenName, {
            x: rootWidget.targetX,
            y: rootWidget.targetY,
            placementStrategy: rootWidget.placementStrategy
        }, surface);
    }

    width: gridSize ? gridSpanWidth
        : Math.max(manifest ? (manifest.defaultWidth || 0) : 0, pluginNode.width)
    height: gridSize ? gridSpanHeight
        : Math.max(manifest ? (manifest.defaultHeight || 0) : 0, pluginNode.height)

    readonly property bool frostSuspended: (GlobalStates.screenLocked
            && Config.options.lock.blur.enable)
        || GlobalStates.editMode
    Repeater {
        model: rootWidget.frostBlur && rootWidget.blurEnabled && !rootWidget.frostSuspended
            && rootWidget.hasBlurSurface
            && (Config.options.appearance.transparency.enable || rootWidget.keepTranslucent)
            ? (pluginNode.hasCustomBlurRegions
                ? pluginNode.blurRegions
                : [{ x: 0, y: 0, width: rootWidget.width,
                    height: rootWidget.height, radius: rootWidget.widgetRounding }])
            : []

        WallpaperBlurSurface {
            required property var modelData
            z: 0
            x: Number(modelData.x || 0)
            y: Number(modelData.y || 0)
            width: Number(modelData.width || 0)
            height: Number(modelData.height || 0)
            wallpaperSource: rootWidget.wallpaperPath
            liveWallpaperActive: rootWidget.liveWallpaperActive
            weSurfaceItem: rootWidget.weSurfaceItem
            cornerRadius: Number(modelData.radius ?? rootWidget.widgetRounding)
            maskItem: modelData.mask ?? null
            wallpaperWidth: rootWidget.wallpaperRect.width
            wallpaperHeight: rootWidget.wallpaperRect.height
            surfaceX: rootWidget.frostSampleOrigin.x + x
            surfaceY: rootWidget.frostSampleOrigin.y + y
        }
    }

    Item {
        id: nodeLayerFrame
        z: 1
        anchors.centerIn: parent
        width: pluginNode.width + Tension.BOW_PX * 4
        height: pluginNode.height + Tension.BOW_PX * 4
        layer.enabled: pluginNode.width > 0 && pluginNode.height > 0
        layer.smooth: true

    PluginNode {
        id: pluginNode
        manifestNode: rootWidget.manifest ? rootWidget.manifest.desktopWidget : null
        pluginId: rootWidget.manifest?.id ?? ""
        optionDefinitions: rootWidget.manifest?.options ?? []
        basePath: rootWidget.manifest?._basePath ?? ""
        screenName: rootWidget.screenName
        hostX: rootWidget.x
        hostY: rootWidget.y
        hostColText: rootWidget.colText
        hostWallpaperSafetyTriggered: rootWidget.wallpaperSafetyTriggered
        hostInteractionLocked: rootWidget.interactionLocked
        gridWidth: rootWidget.gridSized ? rootWidget.width : 0
        gridHeight: rootWidget.gridSized ? rootWidget.height : 0
        gridSize: rootWidget.shownGridSpan
        resizeBow: rootWidget.resizeBow
        hostDragging: rootWidget.dragging
        hostBoxInMotion: rootWidget.boxInMotion
        anchors.centerIn: parent
    }
    }

    Rectangle {
        id: resizeHandle
        z: 2
        implicitWidth: 16
        implicitHeight: 16
        radius: Appearance.rounding.unsharpenslight
        color: Appearance.colors.colOnPrimaryContainer
        anchors {
            right: parent.right
            bottom: parent.bottom
            margins: Appearance.spacing.space100
        }
        opacity: (GlobalStates.editMode || rootWidget.containsMouse
                || resizeArea.containsMouse || rootWidget.resizingGrid)
            ? 0.5 : 0
        visible: opacity > 0 && rootWidget.gridResizable && !rootWidget.interactionLocked

        Behavior on opacity {
            animation: Appearance.animation.elementMoveFaster.numberAnimation.createObject(this)
        }

        Keys.onEscapePressed: event => {
            rootWidget.cancelGridResize();
            event.accepted = true;
        }

        MouseArea {
            id: resizeArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton
            cursorShape: Qt.SizeFDiagCursor
            preventStealing: true

            property real pressFrameX: 0
            property real pressFrameY: 0
            property real pressWidth: 0
            property real pressHeight: 0

            onPressed: mouse => {
                const pressPoint = resizeArea.mapToItem(rootWidget.parent, mouse.x, mouse.y);
                resizeArea.pressFrameX = pressPoint.x;
                resizeArea.pressFrameY = pressPoint.y;
                resizeArea.pressWidth = rootWidget.settledWidth;
                resizeArea.pressHeight = rootWidget.settledHeight;
                rootWidget.beginGridResize();
                resizeHandle.forceActiveFocus();
            }
            onPositionChanged: mouse => {
                if (!rootWidget.resizingGrid) return;
                const point = resizeArea.mapToItem(rootWidget.parent, mouse.x, mouse.y);
                rootWidget.previewGridResize(
                    resizeArea.pressWidth + point.x - resizeArea.pressFrameX,
                    resizeArea.pressHeight + point.y - resizeArea.pressFrameY);
            }
            onReleased: {
                rootWidget.endGridResize();
                resizeHandle.focus = false;
            }
            onCanceled: {
                rootWidget.cancelGridResize();
                resizeHandle.focus = false;
            }
        }
    }

}
