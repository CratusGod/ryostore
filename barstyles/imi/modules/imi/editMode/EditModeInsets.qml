pragma Singleton

import Quickshell
import "../../common"
import "../dock/dock_geometry.js" as DockGeometry

Singleton {
    id: root

    readonly property bool barVertical: Config.options?.bar.vertical ?? false
    readonly property string barSide: DockGeometry.barEdge(
        root.barVertical, Config.options?.bar.bottom ?? false)
    readonly property real barThickness: root.barVertical
        ? Appearance.sizes.verticalBarSurfaceWidth
        : Appearance.sizes.barSurfaceThickness

    readonly property string dockSide: DockGeometry.normalizedEdge(
        Config.options?.dock.edge ?? "bottom")
    readonly property real dockThickness: (Config.options?.dock.enable ?? false)
        ? DockGeometry.thickness(Config.options?.dock.height ?? 60,
            Appearance.sizes.elevationMargin, Appearance.sizes.hyprlandGapsOut)
        : 0

    function barShownOn(screenName) {
        const list = Config.options?.bar.screenList;
        return !list || list.length === 0 || list.indexOf(screenName) !== -1;
    }

    function insetsFor(screenName) {
        const insets = { top: 0, bottom: 0, left: 0, right: 0 };
        if (root.barShownOn(screenName))
            insets[root.barSide] += root.barThickness;
        insets[root.dockSide] += root.dockThickness;
        return insets;
    }
}
