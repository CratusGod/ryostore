pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices
import ".."

Singleton {
    id: root

    readonly property bool silent: RyokuServices.Flags.dnd

    property int unread: 0
    property var seenPopupIds: ({})

    component Notif: QtObject {
        id: wrapper
        required property var notification
        readonly property int notificationId: notification.id
        readonly property string appName: notification.appName ?? ""
        readonly property string appIcon: root.resolveAppIcon(notification.appIcon ?? "", wrapper.appName)
        readonly property string body: notification.body ?? ""
        readonly property string image: notification.image ?? ""
        readonly property string summary: notification.summary ?? ""
        readonly property double time: RyokuServices.Notifs.arrivalMs[notification.id] ?? 0
        readonly property var urgency: notification.urgency
        readonly property bool isTransient: notification.transient ?? false
        readonly property bool isRestartRequired: false
        readonly property bool popup: RyokuServices.Notifs.popups.indexOf(notification) !== -1
        readonly property var actions: (notification.actions ?? []).map(action => ({
            "identifier": action.identifier,
            "text": action.text
        }))
    }

    Component {
        id: notifComponent
        Notif {}
    }

    function resolveAppIcon(own, appName) {
        if (own !== "") return own;
        const guessed = AppSearch.guessIcon(appName);
        return guessed === "image-missing" ? "" : guessed;
    }

    readonly property var list: RyokuServices.Notifs.history.map(n => notifComponent.createObject(root, {
        "notification": n
    }))
    readonly property var popupList: RyokuServices.Notifs.popups.map(n => notifComponent.createObject(root, {
        "notification": n
    }))

    function groupsForList(items) {
        const groups = {};
        items.forEach(notif => {
            if (!groups[notif.appName])
                groups[notif.appName] = {
                    appName: notif.appName,
                    appIcon: notif.appIcon,
                    notifications: [],
                    time: 0
                };
            groups[notif.appName].notifications.push(notif);
            groups[notif.appName].time = Math.max(groups[notif.appName].time, notif.time);
        });
        return groups;
    }

    function appNameListForGroups(groups) {
        return Object.keys(groups).sort((a, b) => groups[b].time - groups[a].time);
    }

    readonly property var groupsByAppName: root.groupsForList(root.list)
    readonly property var popupGroupsByAppName: root.groupsForList(root.popupList)
    readonly property var appNameList: root.appNameListForGroups(root.groupsByAppName)
    readonly property var popupAppNameList: root.appNameListForGroups(root.popupGroupsByAppName)

    function markAllRead() {
        root.unread = 0;
    }

    function toggleSilent() {
        RyokuServices.Flags.dnd = !RyokuServices.Flags.dnd;
    }

    function notificationById(id) {
        return root.list.concat(root.popupList).find(notif => notif.notificationId === id);
    }

    function discardNotification(id) {
        const notif = root.notificationById(id);
        if (notif?.notification && typeof notif.notification.dismiss === "function")
            notif.notification.dismiss();
    }

    function discardAllNotifications() {
        RyokuServices.Notifs.clearAll();
    }

    function attemptInvokeAction(id, notifIdentifier) {
        const notif = root.notificationById(id);
        const action = notif?.notification?.actions?.find(action => action.identifier === notifIdentifier);
        if (action) action.invoke();
        root.discardNotification(id);
    }

    function cancelTimeout(id) {}
    function timeoutNotification(id) {
        const notif = RyokuServices.Notifs.popups.find(n => n.id === id);
        if (notif) RyokuServices.Notifs.removePopup(notif);
    }
    function timeoutAll() {
        for (const notification of [...RyokuServices.Notifs.popups])
            RyokuServices.Notifs.removePopup(notification);
    }

    Connections {
        target: RyokuServices.Notifs
        function onPopupsChanged() {
            let added = 0;
            for (const notification of RyokuServices.Notifs.popups) {
                if (root.seenPopupIds[notification.id]) continue;
                root.seenPopupIds[notification.id] = true;
                added++;
            }
            if (added > 0 && !GlobalStates.sidebarRightOpen && !root.silent)
                root.unread += added;
        }
    }
}
