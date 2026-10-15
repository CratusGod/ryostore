import QtQuick
import "../../.."
import "../../common"
import "../../common/widgets"

Item {
    id: root

    property var controller: null
    property string bucket: ""
    property string widgetId: ""
    property int visibleIndex: 0

    readonly property int bucketIndex: root.controller
        ? root.controller.bucketNames.indexOf(root.bucket) : -1
    readonly property bool dragging: reorder.dragging

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        cursorShape: Qt.SizeAllCursor
        onWheel: wheel => {
            wheel.accepted = true;
        }
    }

    ReorderDragArea {
        id: reorder
        anchors.fill: parent
        axis: root.controller?.axis ?? "x"
        bucketsProvider: () => root.controller.dropBuckets()
        onDragStarted: root.controller.beginDrag(root.bucketIndex, root.visibleIndex, root.widgetId)
        onTargetChanged: if (reorder.dragging)
            root.controller.dragMoved(reorder.target, reorder.scenePosition)
        onScenePositionChanged: if (reorder.dragging)
            root.controller.dragMoved(reorder.target, reorder.scenePosition)
        onDropped: target => root.controller.commitReorder(root.bucketIndex, root.visibleIndex, target)
        onDragEnded: root.controller.endDrag()
    }

    Connections {
        target: GlobalStates
        function onEditReorderCancel() {
            if (!reorder.dragging) return;
            reorder.cancel();
            root.controller.endDrag();
        }
    }

    EditRemoveBadge {
        anchors.top: parent.top
        anchors.right: parent.right
        z: 2
        visible: !root.dragging
        onClicked: root.controller.removeAt(root.bucketIndex, root.visibleIndex)
    }
}
