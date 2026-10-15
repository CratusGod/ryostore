pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../modules/common"

Singleton {
    id: root

    readonly property bool tabEnabled: Config.options.sidebar?.phone?.enable ?? true
    readonly property bool serviceEnabled: root.tabEnabled && PhoneConnect.enableService
    readonly property string activeDeviceId: PhoneConnect.activeDevice?.id ?? ""
    readonly property bool mirrorActive: root.tabEnabled && (PhoneConnect.activeDevice?.reachable ?? false)

    property var notifications: []
    readonly property int count: root.notifications.length
    readonly property var groupsByAppName: root.groupsForList(root.notifications)
    readonly property list<string> appNameList: root.appNameListForGroups(root.groupsByAppName)

    readonly property int replyRefetchDelay: 800
    readonly property int reconcileInterval: 60000
    readonly property int cacheSaveDelay: 2000

    function validPublicId(id: var): bool {
        return typeof id === "string" && /^[A-Za-z0-9_]+$/.test(id);
    }

    function packageFromInternalId(internalId: var): string {
        const parts = String(internalId ?? "").split("|");
        return (parts.length >= 2 && parts[0] === "0") ? parts[1].trim() : "";
    }

    function iconUrl(path: string): string {
        if (!path || path.length === 0)
            return "";
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function normalizeNotification(publicId: string, deviceId: string, rawProps: var, receivedAt: real): var {
        const props = PhoneConnect.unwrapVariants(rawProps);
        const str = key => typeof props[key] === "string" ? props[key] : "";
        return {
            publicId: publicId,
            deviceId: deviceId,
            internalId: str("internalId"),
            package: root.packageFromInternalId(props.internalId),
            appName: str("appName"),
            title: str("title"),
            text: str("text"),
            ticker: str("ticker"),
            iconPath: str("iconPath"),
            dismissable: props.dismissable !== false,
            replyId: str("replyId"),
            actions: Array.isArray(props.actions) ? props.actions.filter(a => typeof a === "string") : [],
            receivedAt: receivedAt,
            summary: str("title"),
            body: str("text"),
            image: root.iconUrl(str("iconPath")),
            urgency: 1
        };
    }

    function carryReceivedAt(previous: var, fresh: var): var {
        const seen = {};
        for (const n of (previous ?? [])) seen[n.publicId] = n.receivedAt;
        return (fresh ?? []).map(n => seen[n.publicId] === undefined
            ? n : Object.assign({}, n, { receivedAt: seen[n.publicId] }));
    }

    function groupsForList(list: var): var {
        const groups = {};
        (list ?? []).forEach(n => {
            if (!groups[n.appName]) {
                groups[n.appName] = {
                    appName: n.appName,
                    appIcon: n.iconPath,
                    notifications: [],
                    time: 0
                };
            }
            groups[n.appName].notifications.push(n);
            groups[n.appName].time = Math.max(groups[n.appName].time, n.receivedAt || 0);
        });
        return groups;
    }

    function appNameListForGroups(groups: var): var {
        return Object.keys(groups ?? {}).sort((a, b) => groups[b].time - groups[a].time);
    }

    function mirrorsAppName(appName: var, deviceNames: var): bool {
        const lower = String(appName ?? "").toLowerCase();
        if (lower === "") return false;
        if (["kdeconnect", "kde connect", "org.kde.kdeconnect"].includes(lower)) return true;
        return (deviceNames ?? []).some(name => String(name ?? "").toLowerCase() === lower);
    }

    function withCardFields(n: var): var {
        if (!n || typeof n !== "object") return n;
        if (typeof n.summary === "string" && typeof n.body === "string"
                && typeof n.image === "string" && typeof n.urgency === "number")
            return n;
        return Object.assign({}, n, {
            summary: typeof n.summary === "string" ? n.summary : (n.title ?? ""),
            body: typeof n.body === "string" ? n.body : (n.text ?? ""),
            image: typeof n.image === "string" ? n.image : root.iconUrl(n.iconPath ?? ""),
            urgency: typeof n.urgency === "number" ? n.urgency : 1
        });
    }

    function cachedNotificationsFor(json: var, deviceId: string): var {
        let doc;
        try {
            doc = JSON.parse(String(json ?? ""));
        } catch (e) {
            return [];
        }
        const entry = (doc && typeof doc === "object") ? doc[deviceId] : null;
        if (!entry || !Array.isArray(entry.notifications)) return [];
        return entry.notifications
            .filter(n => n && typeof n === "object" && root.validPublicId(n.publicId))
            .map(n => root.withCardFields(n));
    }

    function cacheWith(json: var, deviceId: string, list: var, savedAt: real): string {
        let doc;
        try {
            doc = JSON.parse(String(json ?? ""));
        } catch (e) {
            doc = null;
        }
        if (!doc || typeof doc !== "object" || Array.isArray(doc)) doc = {};
        doc[deviceId] = { savedAt: savedAt, notifications: list ?? [] };
        return JSON.stringify(doc);
    }

    function applyNotifications(list: var, deviceId: string): void {
        if (deviceId !== root.activeDeviceId) return;
        root.notifications = root.carryReceivedAt(root.notifications, list);
        cacheSave.restart();
    }

    function mirrorsDesktopNotification(appName: var): bool {
        return root.mirrorActive
            && root.mirrorsAppName(appName, PhoneConnect.devices.filter(d => d.paired).map(d => d.name));
    }

    function notificationsPath(deviceId: string): string {
        return `/modules/kdeconnect/devices/${deviceId}/notifications`;
    }


    function refresh(): void {
        sweepSettle.restart();
    }

    function sweep(): void {
        if (!root.serviceEnabled || !PhoneConnect.installed) return;
        const deviceId = root.activeDeviceId;
        if (PhoneConnect.backend !== "kdeconnect" || !PhoneConnect.validDeviceId(deviceId)) return;
        const path = root.notificationsPath(deviceId);
        root.enqueue(PhoneConnect.busctlCall("org.kde.kdeconnect.daemon", path, "org.kde.kdeconnect.device.notifications", "activeNotifications", []), text => {
            const data = PhoneConnect.parseBusctlReply(text);
            const ids = (data?.[0] ?? []).filter(id => root.validPublicId(id));
            if (ids.length === 0) { root.applyNotifications([], deviceId); return; }
            const collected = [];
            let answered = 0;
            const receivedAt = Date.now();
            for (const publicId of ids) {
                root.enqueue(PhoneConnect.busctlCall("org.kde.kdeconnect.daemon", `${path}/${publicId}`, "org.freedesktop.DBus.Properties", "GetAll", ["s", "org.kde.kdeconnect.device.notifications.notification"]), leafText => {
                    const leaf = PhoneConnect.parseBusctlReply(leafText);
                    if (leaf !== null) collected.push(root.normalizeNotification(publicId, deviceId, leaf[0] ?? {}, receivedAt));
                    if (++answered === ids.length) root.applyNotifications(collected, deviceId);
                });
            }
        });
    }

    Timer {
        id: sweepSettle
        interval: 120
        onTriggered: {
            if (busProc.running || root.callQueue.length > 0) {
                sweepSettle.restart();
                return;
            }
            root.sweep();
        }
    }


    function dismiss(publicId: string): void {
        const deviceId = root.activeDeviceId;
        if (PhoneConnect.backend !== "kdeconnect" || !PhoneConnect.validDeviceId(deviceId) || !root.validPublicId(publicId)) return;
        root.runAction(PhoneConnect.busctlCall("org.kde.kdeconnect.daemon", `${root.notificationsPath(deviceId)}/${publicId}`, "org.kde.kdeconnect.device.notifications.notification", "dismiss", []));
        root.notifications = root.notifications.filter(n => n.publicId !== publicId);
        cacheSave.restart();
    }

    function dismissAll(): void {
        for (const n of root.notifications.slice())
            if (n.dismissable !== false) root.dismiss(n.publicId);
    }

    function reply(publicId: string, text: string): void {
        const deviceId = root.activeDeviceId;
        const n = root.notifications.find(entry => entry.publicId === publicId) ?? null;
        if (!n || n.replyId === "" || String(text ?? "") === "") return;
        if (PhoneConnect.backend !== "kdeconnect" || !PhoneConnect.validDeviceId(deviceId)) return;
        root.runAction(PhoneConnect.busctlCall("org.kde.kdeconnect.daemon", root.notificationsPath(deviceId), "org.kde.kdeconnect.device.notifications", "sendReply", ["ss", n.replyId, text]));
        replyRefetch.restart();
    }

    function sendAction(publicId: string, key: string): void {
        const deviceId = root.activeDeviceId;
        const n = root.notifications.find(entry => entry.publicId === publicId) ?? null;
        if (!n || n.internalId === "" || String(key ?? "") === "") return;
        if (PhoneConnect.backend !== "kdeconnect" || !PhoneConnect.validDeviceId(deviceId)) return;
        root.runAction(PhoneConnect.busctlCall("org.kde.kdeconnect.daemon", root.notificationsPath(deviceId), "org.kde.kdeconnect.device.notifications", "sendAction", ["ss", n.internalId, key]));
    }

    function runAction(argv: var): void {
        root.enqueue(argv, (text, exitCode, errorText) => {
            if (exitCode !== 0) {
                Quickshell.execDetached(["notify-send",
                    Translation.tr("Phone Connect"),
                    errorText.trim() || Translation.tr("Phone Connect command failed"),
                    "-a", "Shell"
                ]);
            }
        });
    }

    Timer {
        id: replyRefetch
        interval: root.replyRefetchDelay
        onTriggered: root.refresh()
    }


    property var callQueue: []
    property var activeCallback: null

    function enqueue(argv: var, callback: var): void {
        root.callQueue.push({ argv: argv, callback: callback });
        root.pump();
    }

    function pump(): void {
        if (busProc.running || root.callQueue.length === 0) return;
        const next = root.callQueue.shift();
        root.activeCallback = next.callback;
        busProc.exec(next.argv);
    }

    Process {
        id: busProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: StdioCollector {
            id: busOut
        }
        stderr: StdioCollector {
            id: busErr
        }
        onExited: (exitCode, exitStatus) => {
            const callback = root.activeCallback;
            root.activeCallback = null;
            callback?.(busOut.text, exitCode, busErr.text);
            root.pump();
        }
    }


    Connections {
        target: PhoneConnect
        function onDeviceChangeSettled(): void {
            root.refresh();
        }
    }

    onActiveDeviceIdChanged: {
        if (root.activeDeviceId === "") return;
        root.restoreCache();
        root.refresh();
    }

    onServiceEnabledChanged: {
        if (!root.serviceEnabled) {
            root.callQueue = [];
            root.activeCallback = null;
        } else {
            root.refresh();
        }
    }

    Timer {
        interval: root.reconcileInterval
        running: root.serviceEnabled && PhoneConnect.installed && root.activeDeviceId !== ""
        repeat: true
        onTriggered: root.refresh()
    }


    function restoreCache(): void {
        if (!Persistent.ready) return;
        const deviceId = root.activeDeviceId;
        if (deviceId === "") return;
        if (root.notifications.length > 0 && root.notifications[0].deviceId === deviceId) return;
        root.notifications = root.cachedNotificationsFor(Persistent.states.phone?.cachedNotificationsJson ?? "", deviceId);
    }

    Connections {
        target: Persistent
        function onReadyChanged(): void {
            if (Persistent.ready) root.restoreCache();
        }
    }

    Timer {
        id: cacheSave
        interval: root.cacheSaveDelay
        onTriggered: {
            const deviceId = root.activeDeviceId;
            if (!Persistent.ready || !PhoneConnect.validDeviceId(deviceId)) return;
            if (root.notifications.some(n => n.deviceId !== deviceId)) return;
            Persistent.states.phone.cachedNotificationsJson = root.cacheWith(
                Persistent.states.phone.cachedNotificationsJson, deviceId, root.notifications, Date.now());
        }
    }

    Component.onCompleted: {
        root.restoreCache();
        root.refresh();
    }
}
