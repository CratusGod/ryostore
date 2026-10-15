import "../../.."
import "../../../services"
import "../../common/widgets"

NotificationController {
    id: root

    readonly property bool supportsReply: true

    function canReply(notif): bool {
        return (notif?.replyId ?? "") !== "";
    }

    function discard(notif): void {
        PhoneNotifications.dismiss(notif.publicId);
    }
    function openLink(link): void {
        Qt.openUrlExternally(link);
        GlobalStates.sidebarLeftOpen = false;
    }

    function timeout(notif): void {
    }

    function cancelTimeout(notif): void {
    }

    function actionsOf(notif): var {
        return (notif?.actions ?? []).map(key => ({ text: key, identifier: key }));
    }

    function invokeAction(notif, action): void {
        PhoneNotifications.sendAction(notif.publicId, action.identifier);
    }

    function reply(notif, text): void {
        PhoneNotifications.reply(notif.publicId, text);
    }

    function appNames(popup: bool): var {
        return PhoneNotifications.appNameList;
    }

    function groupForApp(appName: string, popup: bool): var {
        return PhoneNotifications.groupsByAppName[appName] ?? null;
    }
}
