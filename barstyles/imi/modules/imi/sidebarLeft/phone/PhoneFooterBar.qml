import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property bool online: false
    readonly property int count: PhoneNotifications.count

    property real appear: 1

    implicitHeight: statusRow.implicitHeight

    ButtonGroup {
        id: statusRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: "sync"
            enabled: root.online
            onClicked: PhoneNotifications.refresh()

            StyledToolTip {
                text: Translation.tr("Sync notifications")
            }
        }

        NotificationStatusButton {
            enabled: false
            Layout.fillWidth: true
            buttonText: root.online
                ? (root.count === 1
                    ? Translation.tr("1 notification")
                    : Translation.tr("%1 notifications").arg(root.count))
                : Translation.tr("Device offline")
        }

        NotificationStatusButton {
            Layout.fillWidth: false
            buttonIcon: root.count > 0 ? "delete_sweep" : "do_not_disturb_on"
            enabled: root.online && root.count > 0
            onClicked: PhoneNotifications.dismissAll()

            StyledToolTip {
                text: root.count > 0
                    ? Translation.tr("Dismiss all phone notifications")
                    : Translation.tr("No notifications to clear")
            }
        }
    }
}
