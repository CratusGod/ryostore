import ".."
import "../../../services"
import "../functions"
import "../functions" as Functions
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Notifications

MouseArea {
    id: root
    property var notificationGroup
    property var notifications: notificationGroup?.notifications ?? []
    property int notificationCount: notifications.length
    property bool multipleNotifications: notificationCount > 1
    property bool anyRestartRequired: notifications.some(n => n.isRestartRequired)
    property bool expanded: false
    property bool popup: false
    property NotificationController controller: NotificationController {}
    property real padding: 10 * Appearance.effectiveScale
    
    property bool isFirst: false
    property bool isLast: false
    
    implicitHeight: background.implicitHeight

    property real dragConfirmThreshold: 70 * Appearance.effectiveScale
    property real dismissOvershoot: 20 * Appearance.effectiveScale
    property var qmlParent: root?.parent?.parent
    property int index: 0
    property var parentDragIndex: qmlParent?.dragIndex
    property var parentDragDistance: qmlParent?.dragDistance
    property var dragIndexDiff: Math.abs(parentDragIndex - index)
    property real xOffset: dragIndexDiff == 0 ? parentDragDistance : 
        Math.abs(parentDragDistance) > dragConfirmThreshold ? 0 :
        dragIndexDiff == 1 ? (parentDragDistance * 0.3) :
        dragIndexDiff == 2 ? (parentDragDistance * 0.1) : 0

    function destroyWithAnimation(left = false) {
        if (qmlParent && qmlParent.resetDrag) qmlParent.resetDrag()
        background.anchors.leftMargin = background.anchors.leftMargin;
        destroyAnimation.left = left;
        destroyAnimation.running = true;
    }

    hoverEnabled: true
    onContainsMouseChanged: {
        if (!root.popup) return;
        if (root.containsMouse) root.notifications.forEach(notif => {
            root.controller.cancelTimeout(notif);
        });
        else root.notifications.forEach(notif => {
            root.controller.timeout(notif);
        });
    }

    SequentialAnimation {
        id: destroyAnimation
        property bool left: true
        running: false

        NumberAnimation {
            target: background.anchors
            property: "leftMargin"
            to: (root.width + root.dismissOvershoot) * (destroyAnimation.left ? -1 : 1)
            duration: Appearance.animation.elementMove.duration
            easing.type: Appearance.animation.elementMove.type
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
        onFinished: () => {
            root.notifications.forEach((notif) => {
                Qt.callLater(() => {
                    root.controller.discard(notif);
                });
            });
        }
    }

    function toggleExpanded() {
        if (expanded) implicitHeightAnim.enabled = true;
        else implicitHeightAnim.enabled = false;
        root.expanded = !root.expanded;
    }

    DragManager {
        id: dragManager
        anchors.fill: parent
        interactive: !expanded
        automaticallyReset: false
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) 
                root.toggleExpanded();
        }

        onClicked: (mouse) => {
            if (mouse.button === Qt.MiddleButton) 
                root.destroyWithAnimation();
        }

        onDraggingChanged: () => {
            if (dragging && qmlParent) {
                qmlParent.dragIndex = root.index ?? root.parent.children.indexOf(root);
            }
        }

        onDragDiffXChanged: () => {
            if (qmlParent) qmlParent.dragDistance = dragDiffX;
        }

        onDragReleased: (diffX, diffY) => {
            if (Math.abs(diffX) > root.dragConfirmThreshold)
                root.destroyWithAnimation(diffX < 0);
            else 
                dragManager.resetDrag();
        }
    }


    StyledRectangularShadow {
        target: background
        visible: popup
        opacity: 0.3
    }

    SegmentedWrapper {
        id: background
        anchors.left: parent.left
        width: parent.width
        color: root.anyRestartRequired ? 
            Functions.ColorUtils.applyAlpha(Appearance.colors.colWarningContainer, 0.95) :
            popup ? Appearance.m3colors.m3surfaceContainer : Appearance.colors.colLayer2
        orientation: Qt.Vertical
        maxRadius: 24 * Appearance.effectiveScale
        
        forceFirst: root.isFirst
        forceLast: root.isLast
        
        anchors.leftMargin: root.xOffset

        Rectangle {
            anchors.fill: parent
            z: 99
            color: "transparent"
            border.width: 0
            border.color: "transparent"
            radius: background.maxRadius || 24 * Appearance.effectiveScale
            visible: false
            
            topLeftRadius: background.rTopLeft || radius
            topRightRadius: background.rTopRight || radius
            bottomLeftRadius: background.rBottomLeft || radius
            bottomRightRadius: background.rBottomRight || radius
        }

        Behavior on anchors.leftMargin {
            enabled: !dragManager.dragging
            NumberAnimation {
                duration: Appearance.animation.elementMove.duration
                easing.type: Appearance.animation.elementMove.type
                easing.bezierCurve: Appearance.animationCurves.expressiveDefaultSpatial
            }
        }
        
        implicitHeight: root.expanded ? 
            row.implicitHeight + padding * 2 :
            Math.min(80 * Appearance.effectiveScale, row.implicitHeight + padding * 2)

        Behavior on implicitHeight {
            id: implicitHeightAnim
            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
        }

        RowLayout {
            id: row
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: root.padding
            spacing: 10 * Appearance.effectiveScale

            NotificationAppIcon {
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: false
                image: root?.multipleNotifications ? "" : notificationGroup?.notifications[0]?.image ?? ""
                appIcon: root.notificationGroup?.appIcon
                summary: root.notificationGroup?.notifications[root.notificationCount - 1]?.summary
                isRestart: root.anyRestartRequired
                urgency: root.notifications.some(n => n.urgency == NotificationUrgency.Critical) ? 
                    NotificationUrgency.Critical : NotificationUrgency.Normal
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: expanded ? (root.multipleNotifications ? 
                    (notificationGroup?.notifications[root.notificationCount - 1].image != "") ? 35 * Appearance.effectiveScale : 
                    5 * Appearance.effectiveScale : 0) : 0
                
                Behavior on spacing {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }

                Item {
                    id: topRow
                    Layout.fillWidth: true
                    property real fontSize: Appearance.font.pixelSize.smaller
                    property bool showAppName: root.multipleNotifications
                    implicitHeight: Math.max(topTextRow.implicitHeight, expandButton.implicitHeight)

                    RowLayout {
                        id: topTextRow
                        anchors.left: parent.left
                        anchors.right: expandButton.left
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5 * Appearance.effectiveScale
                        StyledText {
                            id: appName
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                            text: (topRow.showAppName ?
                                notificationGroup?.appName :
                                notificationGroup?.notifications[0]?.summary) || ""
                            font.pixelSize: topRow.showAppName ?
                                topRow.fontSize :
                                Appearance.font.pixelSize.small
                            color: root.anyRestartRequired ? 
                                Appearance.colors.colOnWarningContainer : 
                                topRow.showAppName ?
                                    Appearance.colors.colSubtext :
                                    Appearance.colors.colOnLayer2
                        }
                        StyledText {
                            id: timeText
                            Layout.rightMargin: 10 * Appearance.effectiveScale
                            horizontalAlignment: Text.AlignLeft
                            text: NotificationUtils.getFriendlyNotifTimeString(notificationGroup?.time)
                            font.pixelSize: Math.round(topRow.fontSize)
                            color: root.anyRestartRequired ? 
                                Appearance.colors.colOnWarningContainer : 
                                Appearance.colors.colSubtext
                        }
                    }
                    NotificationGroupExpandButton {
                        id: expandButton
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        count: root.notificationCount
                        expanded: root.expanded
                        isRestart: root.anyRestartRequired
                        fontSize: topRow.fontSize
                        onClicked: { root.toggleExpanded() }
                        altAction: () => { root.toggleExpanded() }

                        StyledToolTip {
                            text: "Tip: right-clicking a group\nalso expands it"
                        }
                    }
                }

                StyledListView {
                    id: notificationsColumn
                    implicitHeight: contentHeight
                    Layout.fillWidth: true
                    spacing: expanded ? 5 * Appearance.effectiveScale : 3 * Appearance.effectiveScale
                    interactive: false
                    Behavior on spacing {
                        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                    }
                    model: ScriptModel {
                        values: root.expanded ? root.notifications.slice().reverse() : 
                            root.notifications.slice().reverse().slice(0, 2)
                    }
                    delegate: NotificationItem {
                        required property int index
                        required property var modelData
                        notificationObject: modelData
                        controller: root.controller
                        expanded: root.expanded
                        
                        onlyNotification: (root.notificationCount === 1)
                        opacity: (!root.expanded && index == 1 && root.notificationCount > 2) ? 0.5 : 1
                        visible: root.expanded || (index < 2)
                        anchors.left: parent?.left
                        anchors.right: parent?.right
                    }
                }
            }
        }
    }
}
