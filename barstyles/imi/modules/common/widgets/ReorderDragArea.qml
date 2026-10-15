import QtQuick
import "../functions/layout_ops.js" as LayoutOps

Item {
    id: root

    property var bucketsProvider: null
    property string axis: "x"
    property bool interactive: true

    property var target: null
    property bool abandoned: false
    readonly property bool dragging: dragHandler.active && !root.abandoned
    readonly property point scenePosition: dragHandler.centroid.scenePosition

    signal dragStarted()
    signal dropped(var target)
    signal dragEnded()

    function cancel() {
        if (!dragHandler.active) return;
        root.abandoned = true;
        root.target = null;
    }

    DragHandler {
        id: dragHandler
        target: null
        enabled: root.interactive
        grabPermissions: PointerHandler.CanTakeOverFromAnything

        onActiveChanged: {
            if (active) {
                root.abandoned = false;
                root.target = null;
                root.dragStarted();
                return;
            }
            const landed = root.abandoned ? null : root.target;
            root.target = null;
            if (landed)
                root.dropped(landed);
            root.dragEnded();
        }

        onCentroidChanged: {
            if (!active || root.abandoned || !root.bucketsProvider) return;
            root.target = LayoutOps.dropTarget(root.bucketsProvider(),
                dragHandler.centroid.scenePosition, root.axis);
        }
    }
}
