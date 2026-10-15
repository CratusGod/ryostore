import "../../../common"
import "../../../common/widgets"
import "../../../../services"
import Quickshell.Widgets
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    id: root

    readonly property real minimumUsefulHeight: statusRow.implicitHeight
        + Appearance.spacing.space100 + Appearance.font.pixelSize.large * 2

    ClippingRectangle {
        id: listClip
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: statusRow.top
        anchors.bottomMargin: Appearance.spacing.space100
        radius: Appearance.rounding.normal
        color: "transparent"

        NotificationListView {
            id: listview
            anchors.fill: parent
            popup: false
        }
    }

    Item {
        anchors.fill: listClip

        PagePlaceholder {
            dropIconWhenCramped: true
            shown: Notifications.list.length === 0
            icon: "notifications_active"
            description: Translation.tr("Nothing")
            shape: MaterialShape.Shape.Ghostish
            descriptionHorizontalAlignment: Text.AlignHCenter
        }
    }

    property int entranceTrigger: -1
    property real _convergeLeft: 0
    property real _convergeRight: 0
    property real _statusOpacity: 1
    onEntranceTriggerChanged: {
        statusConverge.stop();
        root._convergeLeft = -40;
        root._convergeRight = 40;
        root._statusOpacity = 0;
        statusConverge.start();
    }
    SequentialAnimation {
        id: statusConverge
        PauseAnimation { duration: Appearance.animation.scale(250) }
        ParallelAnimation {
            NumberAnimation { target: root; property: "_statusOpacity"; from: 0; to: 1; duration: Appearance.animation.scale(320); easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "_convergeLeft"; from: -40; to: 0; duration: Appearance.animation.scale(350); easing.type: Easing.OutCubic }
            NumberAnimation { target: root; property: "_convergeRight"; from: 40; to: 0; duration: Appearance.animation.scale(350); easing.type: Easing.OutCubic }
        }
    }

    ButtonGroup {
        id: statusRow
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "notifications_paused"
            toggled: Notifications.silent
            opacity: root._statusOpacity
            transform: Translate { x: root._convergeLeft }
            onClicked: () => {
                Notifications.toggleSilent();
            }
        }
        NotificationStatusButton {
            enabled: false
            Layout.fillWidth: true
            opacity: root._statusOpacity
            buttonText: Translation.tr("%1 notifications").arg(Notifications.list.length)
        }
        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "delete_sweep"
            opacity: root._statusOpacity
            transform: Translate { x: root._convergeRight }
            onClicked: () => {
                Notifications.discardAllNotifications()
            }
        }
    }
}