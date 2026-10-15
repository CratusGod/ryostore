import ".."
import "../../../services"
import QtQuick

QtObject {
    id: root

    readonly property bool supportsReply: false
    function canReply(notif): bool {
        return false;
    }

    function discard(notif): void {
        Notifications.discardNotification(notif.notificationId);
    }

    function timeout(notif): void {
        Notifications.timeoutNotification(notif.notificationId);
    }

    function cancelTimeout(notif): void {
        Notifications.cancelTimeout(notif.notificationId);
    }

    function resumeTimeout(notif): void {
        Notifications.timeoutNotification(notif.notificationId);
    }

    function actionsOf(notif): var {
        return notif?.actions ?? [];
    }

    function invokeAction(notif, action): void {
        Notifications.attemptInvokeAction(notif.notificationId, action.identifier);
    }

    function reply(notif, text): void {
    }

    function openLink(link): void {
        Qt.openUrlExternally(link);
        GlobalStates.sidebarRightOpen = false;
    }

    function appNames(popup: bool): var {
        return popup ? Notifications.popupAppNameList : Notifications.appNameList;
    }

    function groupForApp(appName: string, popup: bool): var {
        return popup ? Notifications.popupGroupsByAppName[appName]
            : Notifications.groupsByAppName[appName];
    }
}
