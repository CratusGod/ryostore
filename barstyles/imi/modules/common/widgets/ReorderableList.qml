import "../../../services"
import ".."
import QtQuick
import QtQuick.Layouts
import "../functions/layout_ops.js" as LayoutOps

Item {
    id: root

    property var model: []
    property var rowFor: (entry) => ({ icon: "widgets", title: `${entry}` })
    property var available: []
    property string addButtonText: ""
    property var bucketsProvider: null

    property real entryHeight: 48
    property real listSpacing: Appearance.spacing.space25
    readonly property real slotPitch: root.entryHeight + root.listSpacing

    property int dragIndex: -1
    property int gapIndex: -1

    signal addRequested(var id)
    signal removeRequested(int index)
    signal rowDragStarted(int index)
    signal rowDragMoved(var target)
    signal rowDropped(int index, var target)
    signal rowDragEnded()

    readonly property int count: root.model?.length ?? 0
    readonly property int visualCount: root.count
        + (root.gapIndex >= 0 ? 1 : 0) - (root.dragIndex >= 0 ? 1 : 0)

    implicitHeight: rowsArea.height + Appearance.spacing.space100 + addRow.implicitHeight
    Layout.fillWidth: true

    function bucketFor(holeIndex) {
        const centres = [];
        for (let i = 0; i < root.count; i++) {
            const item = rowRepeater.itemAt(i);
            const hole = !item || i === holeIndex;
            centres.push(hole ? null : item.mapToItem(null, item.width / 2, item.height / 2));
        }
        return {
            centres: centres,
            anchor: rowsArea.mapToItem(null, rowsArea.width / 2, rowsArea.height / 2)
        };
    }

    function beginRow(index) {
        if (root.dragIndex === index) return;
        root.dragIndex = index;
        root.rowDragStarted(index);
    }

    function finishDrag(index, target) {
        root.dragIndex = -1;
        root.rowDropped(index, target);
    }
    function settleDrag() {
        root.dragIndex = -1;
        root.rowDragEnded();
    }

    Item {
        id: rowsArea
        width: root.width
        height: Math.max(root.visualCount, 1) * root.slotPitch - root.listSpacing

        Behavior on height {
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        Repeater {
            id: rowRepeater
            model: root.model

            delegate: Rectangle {
                id: row
                required property var modelData
                required property int index
                readonly property var info: root.rowFor(row.modelData)
                readonly property bool lifted: root.dragIndex === row.index
                readonly property int slot: LayoutOps.partedSlot(
                    row.index, root.dragIndex, root.gapIndex)
                readonly property bool isFirst: !row.lifted && row.slot === 0
                readonly property bool isLast: !row.lifted
                    && row.slot === root.visualCount - 1

                width: rowsArea.width
                height: root.entryHeight
                property real dragY: 0
                onLiftedChanged: if (row.lifted) row.dragY = row.index * root.slotPitch
                y: row.lifted ? row.dragY : row.slot * root.slotPitch
                z: row.lifted ? 10 : 0
                Behavior on y {
                    enabled: !row.lifted
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Connections {
                    target: reorder
                    enabled: row.lifted
                    function onScenePositionChanged() {
                        const local = rowsArea.mapFromItem(null,
                            reorder.scenePosition.x, reorder.scenePosition.y);
                        row.dragY = local.y - root.entryHeight / 2;
                    }
                }

                color: row.lifted ? Appearance.colors.colLayer2Active
                                  : Appearance.colors.colLayer1
                Behavior on color {
                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                }
                scale: row.lifted ? 1.02 : 1
                opacity: row.lifted ? 0.85 : 1
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                Behavior on opacity {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                topLeftRadius: row.isFirst ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                topRightRadius: row.isFirst ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                bottomLeftRadius: row.isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                bottomRightRadius: row.isLast ? Appearance.rounding.normal : Appearance.rounding.unsharpenmore
                Behavior on topLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on topRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on bottomLeftRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }
                Behavior on bottomRightRadius { animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this) }

                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.space150
                        rightMargin: Appearance.spacing.space100
                    }
                    spacing: Appearance.spacing.space150

                    MaterialSymbol {
                        id: handle
                        text: "drag_indicator"
                        iconSize: Appearance.font.pixelSize.larger
                        color: Appearance.colors.colOutline

                        MouseArea {
                            id: holdArea
                            anchors.fill: parent
                            anchors.margins: -Appearance.spacing.space100
                            hoverEnabled: true
                            cursorShape: row.lifted ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                            pressAndHoldInterval: 200
                            onPressAndHold: if (root.dragIndex === -1) root.beginRow(row.index)
                            function unliftIfIdle() {
                                if (reorder.dragging) return;
                                if (root.dragIndex !== row.index) return;
                                root.settleDrag();
                            }
                            onReleased: unliftIfIdle()
                            onCanceled: unliftIfIdle()
                        }
                        ReorderDragArea {
                            id: reorder
                            anchors.fill: holdArea
                            axis: "y"
                            bucketsProvider: root.bucketsProvider
                            onDragStarted: root.beginRow(row.index)
                            onTargetChanged: if (reorder.dragging) root.rowDragMoved(reorder.target)
                            onScenePositionChanged: if (reorder.dragging) root.rowDragMoved(reorder.target)
                            onDropped: target => root.finishDrag(row.index, target)
                            onDragEnded: root.settleDrag()
                        }
                    }

                    MaterialSymbol {
                        text: row.info?.icon ?? "widgets"
                        iconSize: Appearance.font.pixelSize.huge
                        color: Appearance.colors.colPrimary
                        fill: 1
                    }

                    StyledText {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        color: Appearance.colors.colOnLayer1
                        font.pixelSize: Appearance.font.pixelSize.normal
                        text: row.info?.title ?? `${row.modelData}`
                    }

                    IconButton {
                        buttonSize: 32
                        buttonIcon: "close"
                        tooltip: Translation.tr("Remove")
                        colRipple: Appearance.colors.colLayer2Active
                        onClicked: root.removeRequested(row.index)
                    }
                }
            }
        }
    }

    RowLayout {
        id: addRow
        anchors {
            top: rowsArea.bottom
            topMargin: Appearance.spacing.space100
            left: parent.left
            right: parent.right
        }
        spacing: Appearance.spacing.space50

        StyledComboBox {
            id: picker
            Layout.fillWidth: true
            Layout.minimumWidth: 0
            model: root.available
            textRole: "name"
            enabled: root.available.length > 0
        }

        RippleButton {
            implicitHeight: picker.implicitHeight
            buttonRadius: Appearance.rounding.full
            enabled: root.available.length > 0
            colBackground: Appearance.colors.colSecondaryContainer
            colBackgroundHover: Appearance.colors.colSecondaryContainerHover
            colRipple: Appearance.colors.colSecondaryContainerActive
            contentItem: StyledText {
                anchors.centerIn: parent
                leftPadding: Appearance.spacing.space200
                rightPadding: Appearance.spacing.space200
                horizontalAlignment: Text.AlignHCenter
                color: Appearance.colors.colOnSecondaryContainer
                font.pixelSize: Appearance.font.pixelSize.small
                text: root.addButtonText
            }
            onClicked: {
                const chosen = root.available[picker.currentIndex];
                if (chosen) root.addRequested(chosen.id);
            }
        }
    }
}
