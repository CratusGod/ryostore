import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../phone"
import QtQuick

Item {
    id: root

    property real appear: 1

    readonly property int count: PhoneNotifications.count
    readonly property string emptyTitle: {
        if (!PhoneConnect.installed) return Translation.tr("busctl was not found");
        if (!PhoneConnect.available) return Translation.tr("No phone daemon is running");
        if (PhoneConnect.devices.length === 0) return Translation.tr("No devices yet");
        return Translation.tr("No notifications");
    }
    readonly property string emptyDescription: {
        if (!PhoneConnect.installed) return Translation.tr("Phone Connect drives KDE Connect and Valent over D-Bus through busctl, which ships with systemd.");
        if (!PhoneConnect.available) return Translation.tr("Start KDE Connect or Valent to see your phone here.");
        if (PhoneConnect.devices.length === 0) return Translation.tr("Pair your phone from KDE Connect or Valent and it will appear here.");
        return Translation.tr("Make sure KDE Connect has Notification Access on your phone.");
    }

    PagePlaceholder {
        shown: root.count === 0
        dropIconWhenCramped: true
        icon: PhoneConnect.devices.length === 0 ? "mobile_off" : "notifications_off"
        shape: MaterialShape.Shape.Ghostish
        title: root.emptyTitle
        description: root.emptyDescription
        descriptionHorizontalAlignment: Text.AlignHCenter
    }

    NotificationListView {
        id: listView
        anchors.fill: parent
        visible: root.count > 0
        clip: true
        controller: PhoneNotificationController {}
    }
}
