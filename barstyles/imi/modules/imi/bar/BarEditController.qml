import QtQuick
import "../../.."
import "../../common"
import "../../common/plugins"
import "../../common/widgets"
import "../../common/functions/layout_ops.js" as LayoutOps
import "../../common/functions/edit_mode.js" as EditMode

Item {
    id: root

    property bool vertical: false
    readonly property string axis: root.vertical ? "y" : "x"
    readonly property var bucketNames: ["left", "middle", "right"]

    property var slotItemsFor: null
    property var widgetVisible: null
    property Item leftZone: null
    property Item middleZone: null
    property Item rightZone: null

    property int dragBucket: -1
    property int dragVisibleIndex: -1
    property string dragWidgetId: ""
    readonly property bool dragActive: root.dragVisibleIndex >= 0

    function zoneFor(bucket) {
        return [root.leftZone, root.middleZone, root.rightZone][bucket] ?? null;
    }

    function storedLayout(bucket) {
        if (bucket === 0) return Config.options.bar.layouts.leftLayout;
        if (bucket === 1) return Config.options.bar.layouts.middleLayout;
        return Config.options.bar.layouts.rightLayout;
    }

    function writeLayout(bucket, list) {
        if (bucket === 0) Config.options.bar.layouts.leftLayout = list;
        else if (bucket === 1) Config.options.bar.layouts.middleLayout = list;
        else Config.options.bar.layouts.rightLayout = list;
    }

    function flagsFor(bucket) {
        const stored = root.storedLayout(bucket);
        const count = stored && typeof stored.length === "number" ? stored.length : 0;
        const flags = [];
        for (let i = 0; i < count; i++)
            flags.push(root.widgetVisible(stored[i]) === true);
        return flags;
    }

    function dropBuckets() {
        const buckets = [];
        for (let b = 0; b < 3; b++) {
            const items = root.slotItemsFor ? (root.slotItemsFor(root.bucketNames[b]) || []) : [];
            const centres = [];
            for (let i = 0; i < items.length; i++) {
                const item = items[i];
                const hole = !item || (b === root.dragBucket && i === root.dragVisibleIndex);
                centres.push(hole ? null : item.mapToItem(null, item.width / 2, item.height / 2));
            }
            const zone = root.zoneFor(b);
            buckets.push({
                centres: centres,
                anchor: zone ? zone.mapToItem(null, zone.width / 2, zone.height / 2) : null
            });
        }
        return buckets;
    }

    function beginDrag(bucket, visibleIndex, widgetId) {
        root.dragBucket = bucket;
        root.dragVisibleIndex = visibleIndex;
        root.dragWidgetId = widgetId;
        GlobalStates.editBarDragActive = true;
    }

    function endDrag() {
        root.dragBucket = -1;
        root.dragVisibleIndex = -1;
        root.dragWidgetId = "";
        GlobalStates.editBarDragActive = false;
        dropIndicator.shown = false;
        ghost.shown = false;
    }

    property Connections modeWatcher: Connections {
        target: GlobalStates
        function onEditModeChanged() {
            if (!GlobalStates.editMode) root.endDrag();
        }
    }

    function dragMoved(target, scenePoint) {
        if (!root.dragActive) return;
        const local = root.mapFromItem(null, scenePoint.x, scenePoint.y);
        ghost.x = local.x - ghost.width / 2;
        ghost.y = local.y - ghost.height - Appearance.spacing.space100;
        ghost.shown = true;
        root.placeIndicator(target);
    }

    function placeIndicator(target) {
        if (!target) {
            dropIndicator.shown = false;
            return;
        }
        const items = root.slotItemsFor(root.bucketNames[target.bucket]) || [];
        let along;
        let crossCentre;
        let crossSize;
        const atEnd = target.index >= items.length;
        const reference = items.length === 0 ? null
            : items[atEnd ? items.length - 1 : target.index];
        if (!reference) {
            const zone = root.zoneFor(target.bucket);
            if (!zone) {
                dropIndicator.shown = false;
                return;
            }
            const centre = zone.mapToItem(root, zone.width / 2, zone.height / 2);
            along = root.vertical ? centre.y : centre.x;
            crossCentre = root.vertical ? centre.x : centre.y;
            crossSize = root.vertical ? zone.width : zone.height;
        } else {
            const topLeft = reference.mapToItem(root, 0, 0);
            const size = root.vertical ? reference.height : reference.width;
            const start = root.vertical ? topLeft.y : topLeft.x;
            along = atEnd ? start + size : start;
            crossCentre = root.vertical
                ? topLeft.x + reference.width / 2
                : topLeft.y + reference.height / 2;
            crossSize = root.vertical ? reference.width : reference.height;
        }
        if (root.vertical) {
            dropIndicator.width = crossSize;
            dropIndicator.height = 3;
            dropIndicator.x = crossCentre - crossSize / 2;
            dropIndicator.y = along - dropIndicator.height / 2;
        } else {
            dropIndicator.width = 3;
            dropIndicator.height = crossSize;
            dropIndicator.x = along - dropIndicator.width / 2;
            dropIndicator.y = crossCentre - crossSize / 2;
        }
        dropIndicator.shown = true;
    }

    function pushUndoForBuckets(buckets) {
        const snap = [];
        for (const bucket of buckets)
            snap.push({ bucket: bucket, list: EditMode.listCopy(root.storedLayout(bucket)) });
        GlobalStates.editUndoPush(() => {
            for (const entry of snap) {
                if (entry.bucket === 0) Config.options.bar.layouts.leftLayout = entry.list;
                else if (entry.bucket === 1) Config.options.bar.layouts.middleLayout = entry.list;
                else Config.options.bar.layouts.rightLayout = entry.list;
            }
        });
    }

    function commitReorder(fromBucket, fromVisible, target) {
        if (!GlobalStates.editMode || !target) return;
        if (target.bucket === fromBucket) {
            const flags = root.flagsFor(fromBucket);
            const visibleDest = LayoutOps.moveTargetForInsertion(fromVisible, target.index);
            if (visibleDest === fromVisible) return;
            root.pushUndoForBuckets([fromBucket]);
            root.writeLayout(fromBucket, LayoutOps.move(root.storedLayout(fromBucket),
                LayoutOps.nthVisible(flags, fromVisible),
                LayoutOps.nthVisible(flags, visibleDest)));
            return;
        }
        const fromFlags = root.flagsFor(fromBucket);
        const toFlags = root.flagsFor(target.bucket);
        const storedFrom = LayoutOps.nthVisible(fromFlags, fromVisible);
        if (storedFrom === -1) return;
        root.pushUndoForBuckets([fromBucket, target.bucket]);
        const source = root.storedLayout(fromBucket);
        const id = source[storedFrom];
        root.writeLayout(fromBucket, LayoutOps.remove(source, storedFrom));
        root.writeLayout(target.bucket, LayoutOps.insert(root.storedLayout(target.bucket),
            id, LayoutOps.insertionForVisible(toFlags, target.index)));
    }

    function removeAt(bucket, visibleIndex) {
        if (!GlobalStates.editMode) return;
        const flags = root.flagsFor(bucket);
        const stored = LayoutOps.nthVisible(flags, visibleIndex);
        if (stored === -1) return;
        root.pushUndoForBuckets([bucket]);
        root.writeLayout(bucket, LayoutOps.remove(root.storedLayout(bucket), stored));
    }

    Rectangle {
        id: dropIndicator
        objectName: "barEditDropIndicator"
        property bool shown: false
        visible: root.dragActive && shown
        radius: Appearance.rounding.unsharpen
        color: Appearance.colors.colPrimary
    }

    Rectangle {
        id: ghost
        objectName: "barEditGhost"
        property bool shown: false
        visible: root.dragActive && shown
        width: ghostLabel.implicitWidth + Appearance.spacing.space200
        height: 28
        radius: height / 2
        color: Appearance.colors.colSecondaryContainer

        StyledText {
            id: ghostLabel
            anchors.centerIn: parent
            text: BarWidgets.nameFor(root.dragWidgetId)
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
}
