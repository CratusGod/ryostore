import QtQuick
import Quickshell
import Quickshell.Wayland
import "../../.."
import "../../../services"
import "../../common"
import "../../common/plugins"
import "../../common/functions/edit_mode.js" as EditMode
import "../../common/functions/layout_ops.js" as LayoutOps
import "../../common/plugins/gridSizes.js" as GridSizes

PanelWindow {
    id: root

    color: "transparent"
    WlrLayershell.namespace: "quickshell:editMode"
    property bool underneath: false

    WlrLayershell.layer: root.underneath ? WlrLayer.Bottom : WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: 0

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    readonly property var insets: EditModeInsets.insetsFor(root.screen?.name ?? "")
    readonly property var viewport: EditMode.viewportGeometry({
        screenWidth: root.width,
        screenHeight: root.height,
        drawerWidth: Appearance.sizes.editModeDrawerWidth,
        margin: Appearance.sizes.editModeMargin,
        edgeMargin: Appearance.sizes.editModeEdgeMargin,
        chromeThickness: Appearance.sizes.toolbarHeight,
        insetTop: root.insets.top,
        insetBottom: root.insets.bottom,
        insetLeft: root.insets.left,
        insetRight: root.insets.right
    })

    readonly property real editShift: EditMode.drawerTravel(root.viewport)
        * GlobalStates.editDrawerProgress

    mask: Region {
        item: chrome.toolbarItem
        Region {
            item: chrome.tabBarItem
        }
        Region {
            item: chrome.drawerItem
        }
    }

    readonly property rect drawerReveal: chrome.drawer
    onDrawerRevealChanged: root.publishDrawerReveal(root.drawerReveal)
    Component.onCompleted: root.publishDrawerReveal(root.drawerReveal)
    Component.onDestruction: root.publishDrawerReveal(null)
    function publishDrawerReveal(reveal) {
        const name = root.screen?.name ?? "";
        const published = Object.assign({}, GlobalStates.editDrawerReveals);
        if (reveal === null)
            delete published[name];
        else
            published[name] = reveal;
        GlobalStates.editDrawerReveals = published;
    }

    function enabledWithout(id) {
        return EditMode.enabledWithout(Config.options.plugins.enabled, id);
    }

    function enablePlugin(id) {
        if (Config.options.plugins.enabled.includes(id))
            return;
        const next = root.enabledWithout(id);
        next.push(id);
        Config.setNestedValue("plugins.enabled", next);
    }

    function togglePlugin(manifest) {
        const before = EditMode.listCopy(Config.options.plugins.enabled);
        GlobalStates.editUndoPush(() =>
            Config.setNestedValue("plugins.enabled", before));
        if (Config.options.plugins.enabled.includes(manifest.id))
            Config.setNestedValue("plugins.enabled", root.enabledWithout(manifest.id));
        else
            root.enablePlugin(manifest.id);
    }

    function spanSizeFor(manifest) {
        const span = GridSizes.resolveSize(manifest.grid,
            PluginState.gridSize(manifest.id, root.screen?.name ?? "") ?? "");
        if (!span)
            return { width: 0, height: 0 };
        return {
            width: Appearance.sizes.widgetGridSpanX(span.cols),
            height: Appearance.sizes.widgetGridSpanY(span.rows)
        };
    }

    function appendBarWidget(widgetId, bucket) {
        if (bucket === "left") {
            const beforeLeft = EditMode.listCopy(Config.options.bar.layouts.leftLayout);
            GlobalStates.editUndoPush(() => {
                Config.options.bar.layouts.leftLayout = beforeLeft;
            });
        } else if (bucket === "middle") {
            const beforeMiddle = EditMode.listCopy(Config.options.bar.layouts.middleLayout);
            GlobalStates.editUndoPush(() => {
                Config.options.bar.layouts.middleLayout = beforeMiddle;
            });
        } else {
            const beforeRight = EditMode.listCopy(Config.options.bar.layouts.rightLayout);
            GlobalStates.editUndoPush(() => {
                Config.options.bar.layouts.rightLayout = beforeRight;
            });
        }
        if (bucket === "left")
            Config.options.bar.layouts.leftLayout = LayoutOps.insert(
                Config.options.bar.layouts.leftLayout, widgetId,
                Config.options.bar.layouts.leftLayout.length);
        else if (bucket === "middle")
            Config.options.bar.layouts.middleLayout = LayoutOps.insert(
                Config.options.bar.layouts.middleLayout, widgetId,
                Config.options.bar.layouts.middleLayout.length);
        else
            Config.options.bar.layouts.rightLayout = LayoutOps.insert(
                Config.options.bar.layouts.rightLayout, widgetId,
                Config.options.bar.layouts.rightLayout.length);
    }

    function toggleLockIsland(key) {
        if (key === "showToolbars") {
            const beforeToolbars = Config.options.lock.showToolbars;
            GlobalStates.editUndoPush(() => {
                Config.options.lock.showToolbars = beforeToolbars;
            });
            Config.options.lock.showToolbars = !Config.options.lock.showToolbars;
        } else if (key === "showMedia") {
            const beforeMedia = Config.options.lock.showMedia;
            GlobalStates.editUndoPush(() => {
                Config.options.lock.showMedia = beforeMedia;
            });
            Config.options.lock.showMedia = !Config.options.lock.showMedia;
        } else if (key === "showWidgets") {
            const beforeWidgets = Config.options.lock.showWidgets;
            GlobalStates.editUndoPush(() => {
                Config.options.lock.showWidgets = beforeWidgets;
            });
            Config.options.lock.showWidgets = !Config.options.lock.showWidgets;
        }
    }

    function toggleLockWidget(pluginId) {
        const before = PluginState.lockPresenceRecords();
        GlobalStates.editUndoPush(() => PluginState.restoreLockPresence(before));
        PluginState.setLockWidgetEnabled(pluginId,
            !PluginState.lockWidgetEnabled(pluginId));
    }

    function resetLockPresence() {
        if (!PluginState.lockPresenceForked()) return;
        const forked = PluginState.lockPresenceRecords();
        GlobalStates.editUndoPush(() => PluginState.restoreLockPresence(forked));
        PluginState.resetLockPresence();
    }

    function resetLockLayout() {
        const screen = root.screen?.name ?? "";
        if (!PluginState.lockLayoutForked(screen)) return;
        const forked = PluginState.lockRecords(screen);
        GlobalStates.editUndoPush(() => PluginState.restoreLockRecords(screen, forked));
        PluginState.resetLockLayout(screen);
    }

    function addWidgetAt(manifest, dropX, dropY) {
        if (EditMode.pointInDrawerReveal(chrome.drawer, dropX, dropY))
            return;
        const point = EditMode.canvasPointFromScreen(root.viewport,
            GlobalStates.editProgress, root.editShift, dropX, dropY);
        const span = root.spanSizeFor(manifest);
        const placed = EditMode.dropPosition({
            canvasX: point.x,
            canvasY: point.y,
            widgetWidth: span.width,
            widgetHeight: span.height,
            screenWidth: root.width,
            screenHeight: root.height
        });
        const id = manifest.id;
        const screen = root.screen?.name ?? "";
        const beforeEnabled = EditMode.listCopy(Config.options.plugins.enabled);
        const surface = PluginState.currentSurface;
        const beforeRaw = PluginState.rawPosition(id, screen, surface);
        const beforePosition = beforeRaw !== undefined ? PluginState.position(id, screen, surface) : null;
        GlobalStates.editUndoPush(() => {
            Config.setNestedValue("plugins.enabled", beforeEnabled);
            if (beforePosition)
                PluginState.setPosition(id, screen, beforePosition, surface);
        });
        PluginState.setPosition(manifest.id, root.screen?.name ?? "",
            { x: placed.x, y: placed.y, placementStrategy: "free" }, surface);
        root.enablePlugin(manifest.id);
    }

    EditModeChromeContent {
        id: chrome
        anchors.fill: parent
        card: EditMode.cardRect(root.viewport, GlobalStates.editProgress,
            root.width, root.height, root.editShift)
        drawer: EditMode.drawerRect(root.viewport, GlobalStates.editProgress,
            GlobalStates.editDrawerProgress, root.width, root.height)
        area: EditMode.areaRect(root.viewport, GlobalStates.editProgress,
            root.width, root.height)
        bandFraction: EditMode.chromeBandFraction(root.viewport)
        opacity: GlobalStates.editProgress
        onDoneRequested: GlobalStates.editMode = false
        onDrawerToggleRequested: GlobalStates.editDrawerOpen = !GlobalStates.editDrawerOpen
        onWidgetDropRequested: (manifest, dropX, dropY) => root.addWidgetAt(manifest, dropX, dropY)
        onWidgetToggleRequested: (manifest) => root.togglePlugin(manifest)
        onBarWidgetAddRequested: (widgetId, bucket) => root.appendBarWidget(widgetId, bucket)
        onDockAppToggleRequested: (appId) => {
            const toggled = appId;
            GlobalStates.editUndoPush(() => TaskbarApps.togglePin(toggled));
            TaskbarApps.togglePin(appId);
        }
        onLockIslandToggleRequested: (key) => root.toggleLockIsland(key)
        onLockWidgetToggleRequested: (pluginId) => root.toggleLockWidget(pluginId)
        onLockLayoutResetRequested: root.resetLockLayout()
        onLockPresenceResetRequested: root.resetLockPresence()
        screenName: root.screen?.name ?? ""
        onSnapToggleRequested: Config.options.background.showSnapLines = !Config.options.background.showSnapLines
    }
}
