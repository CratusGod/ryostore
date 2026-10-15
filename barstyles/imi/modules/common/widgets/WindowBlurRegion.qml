import QtQuick
import Quickshell
import Quickshell.Wayland

Item {
    id: root
    visible: false

    required property var targetWindow
    property Item regionItem
    property int regionRadius: 0

    property Region region: Region {
        item: root.regionItem
        radius: root.regionRadius
    }

    property var regionItems: []
    property int regionItemsRadius: 0

    Component {
        id: subRegionComponent
        Region {}
    }

    property var subRegions: []

    function rebuildFromItems() {
        if (root.subRegions.length === 0 && (root.regionItems?.length ?? 0) === 0)
            return;

        for (const stale of root.subRegions)
            if (stale)
                stale.destroy();

        let built = [];
        for (const item of (root.regionItems ?? [])) {
            if (!item)
                continue;
            built.push(subRegionComponent.createObject(root, {
                item: item,
                radius: root.regionItemsRadius
            }));
        }
        root.subRegions = built;
        root.region.regions = built;
        root.republish();
    }

    onRegionItemsChanged: root.rebuildFromItems()

    function republish() {
        if (!root.targetWindow)
            return;
        root.targetWindow.BackgroundEffect.blurRegion = null;
        root.targetWindow.BackgroundEffect.blurRegion = root.region;
    }

    onRegionChanged: root.publishNow()

    Timer {
        id: settleTimer
        interval: 96
        repeat: false
        onTriggered: root.republish()
    }

    function publishNow(): void {
        root.republish();
        settleTimer.restart();
    }

    Connections {
        target: root.targetWindow ?? null
        ignoreUnknownSignals: true
        function onVisibleChanged() {
            if (root.targetWindow.visible)
                root.publishNow();
        }
        function onWidthChanged() {
            root.publishNow();
        }
        function onHeightChanged() {
            root.publishNow();
        }
    }

    Component.onCompleted: {
        if (targetWindow)
            targetWindow.BackgroundEffect.blurRegion = region;
        settleTimer.restart();
    }
    Component.onDestruction: {
        if (targetWindow && targetWindow.BackgroundEffect)
            targetWindow.BackgroundEffect.blurRegion = null;
    }
}
