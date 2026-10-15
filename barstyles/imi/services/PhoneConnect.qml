pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../modules/common"

Singleton {
    id: root

    readonly property int pollInterval: Config.options.networking?.phoneConnect?.pollInterval ?? 10000
    readonly property bool enableService: Config.options.networking?.phoneConnect?.enable ?? true

    property bool installed: false
    property string backend: "none"
    readonly property bool available: root.backend !== "none"
    property var devices: []
    readonly property var pairingRequests: root.devices.filter(d => d.hasPairingRequest === true)

    readonly property string persistedActiveDeviceId: Persistent.states?.phone?.activeDeviceId ?? ""
    readonly property var activeDevice: root.preferredActiveDevice(root.devices, root.persistedActiveDeviceId)
    readonly property string materialSymbol: (root.available && root.activeDevice) ? "mobile" : "mobile_off"

    readonly property bool canPing: root.backend === "kdeconnect"
    readonly property bool canSendClipboard: root.backend === "kdeconnect"
    readonly property bool canShare: root.backend === "kdeconnect"
    readonly property bool canBrowseFiles: root.backend === "kdeconnect"

    property string lastActionError: ""
    signal actionFeedback(string message, bool ok)

    function reportFailure(message: string): void {
        root.lastActionError = message;
        root.actionFeedback(message, false);
    }

    signal deviceChangeSettled()

    function parseBusctlReply(text: string): var {
        const trimmed = (text ?? "").trim();
        if (trimmed.length === 0) return null;
        let doc;
        try {
            doc = JSON.parse(trimmed);
        } catch (e) {
            return null;
        }
        if (!doc || typeof doc !== "object" || !Array.isArray(doc.data)) return null;
        return doc.data;
    }

    function unwrapVariants(dict: var): var {
        const out = {};
        for (const key in (dict ?? {})) {
            const cell = dict[key];
            out[key] = (cell && typeof cell === "object" && "data" in cell) ? cell.data : cell;
        }
        return out;
    }

    function backendFromNames(names: var): string {
        const list = names ?? [];
        if (list.includes("org.kde.kdeconnect.daemon")) return "kdeconnect";
        if (list.includes("ca.andyholmes.Valent")) return "valent";
        return "none";
    }

    function normalizeKdeconnectDevice(id: string, rawProps: var, rawBatteryProps: var, rawConnectivityProps: var): var {
        const props = root.unwrapVariants(rawProps);
        const battery = rawBatteryProps === null || rawBatteryProps === undefined
            ? null : root.unwrapVariants(rawBatteryProps);
        const report = rawConnectivityProps === null || rawConnectivityProps === undefined
            ? null : root.unwrapVariants(rawConnectivityProps);
        const addresses = Array.isArray(props.reachableAddresses)
            ? props.reachableAddresses.filter(address => typeof address === "string") : [];
        return {
            id: id,
            name: props.name ?? "",
            type: props.type ?? "",
            reachable: props.isReachable === true,
            paired: props.isPaired === true,
            hasPairingRequest: props.isPairRequestedByPeer === true || props.pairState === 2,
            reachableAddresses: addresses,
            cellularNetworkType: typeof report?.cellularNetworkType === "string" ? report.cellularNetworkType : "",
            cellularNetworkStrength: typeof report?.cellularNetworkStrength === "number" ? report.cellularNetworkStrength : -1,
            batteryAvailable: battery !== null && typeof battery.charge === "number",
            batteryCharge: (battery !== null && typeof battery.charge === "number") ? battery.charge : -1,
            batteryCharging: battery !== null && battery.isCharging === true
        };
    }

    function normalizeValentObjects(managedObjects: var): var {
        const objects = (managedObjects ?? [])[0] ?? {};
        const devices = [];
        for (const path in objects) {
            const ifaces = objects[path];
            const raw = ifaces?.["ca.andyholmes.Valent.Device"];
            if (!raw) continue;
            const props = root.unwrapVariants(raw);
            const state = Number(props.State ?? 0);
            devices.push({
                id: props.Id ?? "",
                name: props.Name ?? "",
                type: props.Type ?? "",
                reachable: (state & 1) !== 0,
                paired: (state & 2) !== 0,
                hasPairingRequest: false,
                reachableAddresses: [],
                cellularNetworkType: "",
                cellularNetworkStrength: -1,
                objectPath: path,
                batteryAvailable: false,
                batteryCharge: -1,
                batteryCharging: false
            });
        }
        return devices;
    }

    function decodeValentBattery(describeAllData: var): var {
        const none = { available: false, charge: -1, charging: false };
        const actions = (describeAllData ?? [])[0] ?? {};
        const batteryAction = actions["battery.state"];
        if (!Array.isArray(batteryAction) || batteryAction.length < 3) return none;
        const stateCells = batteryAction[2];
        if (!Array.isArray(stateCells) || stateCells.length === 0) return none;
        const state = root.unwrapVariants(stateCells[0]?.data ?? null);
        if (typeof state.percentage !== "number") return none;
        return {
            available: state["is-present"] !== false,
            charge: Math.round(state.percentage),
            charging: state.charging === true
        };
    }

    function sortDevices(list: var): var {
        const rank = d => (d.paired && d.reachable) ? 0 : d.paired ? 1 : 2;
        return [...(list ?? [])].sort((a, b) => rank(a) - rank(b)
            || String(a.name || a.id).localeCompare(String(b.name || b.id)));
    }

    function validDeviceId(id: var): bool {
        return typeof id === "string" && /^[A-Za-z0-9_-]+$/.test(id);
    }

    function monitorMatchRule(backend: string): string {
        if (backend === "kdeconnect")
            return "type='signal',sender='org.kde.kdeconnect.daemon',path_namespace='/modules/kdeconnect'";
        return "";
    }

    function parseMonitorLine(line: string): var {
        const trimmed = (line ?? "").trim();
        if (trimmed.length === 0) return null;
        let doc;
        try {
            doc = JSON.parse(trimmed);
        } catch (e) {
            return null;
        }
        if (!doc || typeof doc !== "object" || doc.type !== "signal") return null;
        return {
            path: doc.path ?? "",
            iface: doc.interface ?? "",
            member: doc.member ?? "",
            args: doc.payload?.data ?? []
        };
    }

    function signalChangesDevices(signal: var): bool {
        if (!signal) return false;
        if (signal.iface === "org.freedesktop.DBus.Properties")
            return signal.member === "PropertiesChanged"
                && String((signal.args ?? [])[0] ?? "").startsWith("org.kde.kdeconnect");
        const members = {
            "org.kde.kdeconnect.daemon": ["deviceAdded", "deviceRemoved", "deviceListChanged",
                "deviceVisibilityChanged", "pairingRequestsChanged"],
            "org.kde.kdeconnect.device": ["reachableChanged", "pairStateChanged", "nameChanged",
                "typeChanged", "pluginsChanged"],
            "org.kde.kdeconnect.device.battery": ["refreshed"],
            "org.kde.kdeconnect.device.connectivity_report": ["refreshed"],
            "org.kde.kdeconnect.device.notifications": ["notificationPosted", "notificationUpdated",
                "notificationRemoved", "allNotificationsRemoved"]
        }[signal.iface];
        return Array.isArray(members) && members.includes(signal.member);
    }

    function monitorBackoffDelay(attempt: int): int {
        return Math.min(30000, 1000 * Math.pow(2, Math.max(1, attempt) - 1));
    }

    function monitorExitPlan(attempts: int, ranForMs: int, wanted: bool, healthyMs: int, ceiling: int): var {
        const settled = ranForMs >= healthyMs ? 0 : attempts;
        if (!wanted || settled >= ceiling)
            return { attempts: settled, retry: false, delay: 0 };
        return { attempts: settled + 1, retry: true, delay: root.monitorBackoffDelay(settled + 1) };
    }

    function shareableUrls(entries: var): var {
        if (!Array.isArray(entries)) return [];
        return entries
            .map(entry => typeof entry === "string" ? entry.trim() : "")
            .filter(entry => /^(file|https?):\/\//i.test(entry));
    }

    function clipboardShareTarget(text: var): var {
        const value = (typeof text === "string" ? text : "").trim();
        if (value.length === 0) return { kind: "empty", value: "" };
        if (/^https?:\/\//i.test(value)) return { kind: "url", value: value };
        if (/^[\w.-]+\.\w{2,}(\/|$)/.test(value)) return { kind: "url", value: `https://${value}` };
        return { kind: "text", value: value };
    }

    function pickedFileUrls(text: var): var {
        return (typeof text === "string" ? text : "")
            .split("\n")
            .map(line => line.trim())
            .filter(line => line.startsWith("/"))
            .map(path => "file://" + path.split("/").map(encodeURIComponent).join("/"));
    }

    function sftpStoragePath(mount: var): string {
        const root_ = (typeof mount === "string" ? mount : "").replace(/\/+$/, "");
        return root_.length === 0 ? "" : `${root_}/storage/emulated/0`;
    }

    function sftpBrowseTarget(mount: var, hasStorage: bool): string {
        const root_ = (typeof mount === "string" ? mount : "").replace(/\/+$/, "");
        if (root_.length === 0) return "";
        return hasStorage ? root.sftpStoragePath(root_) : root_;
    }

    function preferredActiveDevice(devices: var, persistedId: var): var {
        const list = devices ?? [];
        return list.find(d => d.id === persistedId && d.paired && d.reachable)
            ?? list.find(d => d.paired && d.reachable && d.type === "phone")
            ?? list.find(d => d.paired && d.reachable)
            ?? null;
    }

    function recentDeviceIdsAfterSelect(list: var, id: var, max: int): var {
        const out = [];
        if (root.validDeviceId(id)) out.push(id);
        const src = list ?? [];
        for (let i = 0; i < (src.length ?? 0); i++) {
            const entry = src[i];
            if (typeof entry === "string" && entry !== id && !out.includes(entry)) out.push(entry);
        }
        return out.slice(0, Math.max(0, max));
    }

    function batteryNoticeTransition(notified: bool, charge: int, charging: bool): var {
        if (charge < 0) return { notice: "", notified: notified };
        if (!notified && charge < 20 && !charging) return { notice: "low", notified: true };
        if (notified && (charge >= 25 || charging)) return { notice: "recovered", notified: false };
        return { notice: "", notified: notified };
    }

    function applyBackend(newBackend: string): void {
        root.backend = newBackend;
        if (newBackend === "none") root.devices = [];
    }

    function applyDevices(list: var): void {
        root.devices = root.sortDevices(list);
    }

    function validValentObjectPath(path: var): bool {
        return typeof path === "string" && /^\/ca\/andyholmes\/Valent\/Device\/[A-Za-z0-9_]+$/.test(path);
    }

    function busctlCall(dest: string, path: string, iface: string, member: string, extra: var): var {
        return ["busctl", "--user", "--json=short", "--timeout=5", "call", dest, path, iface, member, ...extra];
    }

    function busctlMonitor(matchRule: string): var {
        return ["busctl", "--user", "--json=short", "monitor", `--match=${matchRule}`];
    }

    function refresh(): void {
        if (!root.enableService || !root.installed) return;
        if (busProc.running || root.callQueue.length > 0) return;
        root.enqueue(root.busctlCall("org.freedesktop.DBus", "/org/freedesktop/DBus", "org.freedesktop.DBus", "ListNames", []), text => {
            const data = root.parseBusctlReply(text);
            const newBackend = data === null ? "none" : root.backendFromNames(data[0] ?? []);
            root.applyBackend(newBackend);
            if (newBackend === "kdeconnect") root.refreshKdeconnect();
            else if (newBackend === "valent") root.refreshValent();
        });
    }

    function refreshKdeconnect(): void {
        root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", "/modules/kdeconnect", "org.kde.kdeconnect.daemon", "devices", ["bb", "false", "false"]), text => {
            const data = root.parseBusctlReply(text);
            if (data === null) { root.applyDevices([]); return; }
            const ids = (data[0] ?? []).filter(id => root.validDeviceId(id));
            if (ids.length === 0) { root.applyDevices([]); return; }
            const collected = [];
            for (const id of ids) root.collectKdeconnectDevice(id, collected, ids.length);
        });
    }

    function collectKdeconnectDevice(id: string, collected: var, total: int): void {
        const devicePath = `/modules/kdeconnect/devices/${id}`;
        root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", devicePath, "org.freedesktop.DBus.Properties", "GetAll", ["s", "org.kde.kdeconnect.device"]), propsText => {
            const propsData = root.parseBusctlReply(propsText);
            root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", devicePath + "/battery", "org.freedesktop.DBus.Properties", "GetAll", ["s", "org.kde.kdeconnect.device.battery"]), batteryText => {
                const batteryData = root.parseBusctlReply(batteryText);
                root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", devicePath + "/connectivity_report", "org.freedesktop.DBus.Properties", "GetAll", ["s", "org.kde.kdeconnect.device.connectivity_report"]), connText => {
                    const connData = root.parseBusctlReply(connText);
                    collected.push(root.normalizeKdeconnectDevice(id, propsData?.[0] ?? {}, batteryData?.[0] ?? null, connData?.[0] ?? null));
                    if (collected.length === total) root.applyDevices(collected);
                });
            });
        });
    }

    function refreshValent(): void {
        root.enqueue(root.busctlCall("ca.andyholmes.Valent", "/ca/andyholmes/Valent", "org.freedesktop.DBus.ObjectManager", "GetManagedObjects", []), text => {
            const data = root.parseBusctlReply(text);
            if (data === null) { root.applyDevices([]); return; }
            const found = root.normalizeValentObjects(data).filter(d => root.validValentObjectPath(d.objectPath));
            if (found.length === 0) { root.applyDevices([]); return; }
            let pending = found.length;
            for (const device of found) {
                root.enqueue(root.busctlCall("ca.andyholmes.Valent", device.objectPath, "org.gtk.Actions", "DescribeAll", []), describeText => {
                    const battery = root.decodeValentBattery(root.parseBusctlReply(describeText));
                    device.batteryAvailable = battery.available;
                    device.batteryCharge = battery.charge;
                    device.batteryCharging = battery.charging;
                    if (--pending === 0) root.applyDevices(found);
                });
            }
        });
    }


    property string monitorState: "idle"
    property int monitorAttempts: 0
    property real monitorStartedAt: 0

    readonly property int monitorAttemptCeiling: 5
    readonly property int monitorHealthyMs: 30000

    readonly property bool monitorLive: root.monitorState === "running"

    function monitorWanted(): bool {
        return root.enableService && root.installed
            && root.monitorState !== "failed" && root.monitorMatchRule(root.backend) !== "";
    }

    function startMonitor(): void {
        if (monitorProc.running || !root.monitorWanted()) return;
        monitorRestart.stop();
        root.monitorStartedAt = Date.now();
        root.monitorState = "running";
        monitorProc.exec(root.busctlMonitor(root.monitorMatchRule(root.backend)));
    }

    function stopMonitor(): void {
        monitorRestart.stop();
        root.monitorAttempts = 0;
        root.monitorState = "idle";
        monitorProc.running = false;
    }

    function handleMonitorLine(line: string): void {
        if (!root.signalChangesDevices(root.parseMonitorLine(line))) return;
        signalSettle.restart();
    }

    Timer {
        id: signalSettle
        interval: 120
        onTriggered: {
            if (busProc.running || root.callQueue.length > 0) {
                signalSettle.restart();
                return;
            }
            root.refresh();
            root.deviceChangeSettled();
        }
    }

    Timer {
        id: monitorRestart
        onTriggered: root.startMonitor()
    }

    Process {
        id: monitorProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stdout: SplitParser {
            onRead: data => root.handleMonitorLine(data)
        }
        stderr: SplitParser {}
        onExited: (exitCode, exitStatus) => {
            const plan = root.monitorExitPlan(root.monitorAttempts, Date.now() - root.monitorStartedAt,
                root.monitorWanted(), root.monitorHealthyMs, root.monitorAttemptCeiling);
            root.monitorAttempts = plan.attempts;
            if (!plan.retry) {
                if (root.monitorWanted()) {
                    root.monitorState = "failed";
                    console.warn(`[PhoneConnect] busctl monitor gave up after ${root.monitorAttemptCeiling} restarts; falling back to polling`);
                } else {
                    root.monitorState = "idle";
                }
                return;
            }
            root.monitorState = "backoff";
            monitorRestart.interval = plan.delay;
            monitorRestart.restart();
        }
    }

    onBackendChanged: {
        root.monitorAttempts = 0;
        if (root.monitorState === "failed") root.monitorState = "idle";
        if (root.monitorMatchRule(root.backend) === "") root.stopMonitor();
        else root.startMonitor();
    }


    property string batteryNoticeDeviceId: ""
    property bool batteryNoticed: false

    onActiveDeviceChanged: root.observeBattery()

    function observeBattery(): void {
        const d = root.activeDevice;
        if (!d) return;
        if (d.id !== root.batteryNoticeDeviceId) {
            root.batteryNoticeDeviceId = d.id;
            root.batteryNoticed = false;
        }
        if (!d.batteryAvailable) return;
        const next = root.batteryNoticeTransition(root.batteryNoticed, d.batteryCharge, d.batteryCharging);
        root.batteryNoticed = next.notified;
        const name = d.name || Translation.tr("Phone");
        if (next.notice === "low") {
            Quickshell.execDetached(["notify-send", "-i", "phone", "-u", "normal",
                Translation.tr("Low battery: %1").arg(name),
                Translation.tr("Charge is at %1%.").arg(String(d.batteryCharge))]);
        } else if (next.notice === "recovered") {
            Quickshell.execDetached(["notify-send", "-i", "phone", "-u", "low",
                Translation.tr("Battery recovered: %1").arg(name),
                Translation.tr("Charge is back to %1%.").arg(String(d.batteryCharge))]);
        }
    }


    function ring(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d) return;
        if (root.backend === "kdeconnect" && root.validDeviceId(d.id))
            root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/findmyphone`, "org.kde.kdeconnect.device.findmyphone", "ring", []));
        else if (root.backend === "valent" && root.validValentObjectPath(d.objectPath))
            root.runAction(root.busctlCall("ca.andyholmes.Valent", d.objectPath, "org.gtk.Actions", "Activate", ["sava{sv}", "findmyphone.ring", "0", "0"]));
        else return;
        root.actionFeedback(Translation.tr("Ringing phone…"), true);
    }

    function ping(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/ping`, "org.kde.kdeconnect.device.ping", "sendPing", []));
        root.actionFeedback(Translation.tr("Ping sent"), true);
    }

    function sendClipboard(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/clipboard`, "org.kde.kdeconnect.device.clipboard", "sendClipboard", []));
        root.actionFeedback(Translation.tr("Clipboard sent"), true);
    }

    function shareUrls(device: var, urls: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        for (const url of root.shareableUrls(urls))
            root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/share`, "org.kde.kdeconnect.device.share", "shareUrl", ["s", url]));
    }

    function shareText(device: var, text: string): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id) || !text) return;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/share`, "org.kde.kdeconnect.device.share", "shareText", ["s", text]));
    }

    property var clipboardShareDevice: null

    function shareClipboard(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        if (clipboardProc.running) return;
        root.lastActionError = "";
        root.clipboardShareDevice = d;
        clipboardProc.running = true;
    }

    Process {
        id: clipboardProc
        command: ["wl-paste", "--no-newline"]
        stdout: StdioCollector {
            id: clipboardOut
        }
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            const target = root.clipboardShareTarget(clipboardOut.text);
            const d = root.clipboardShareDevice;
            root.clipboardShareDevice = null;
            if (target.kind === "empty") {
                root.reportFailure(Translation.tr("Clipboard is empty"));
            } else if (target.kind === "url") {
                root.shareUrls(d, [target.value]);
                root.actionFeedback(Translation.tr("Link shared"), true);
            } else {
                root.shareText(d, target.value);
                root.actionFeedback(Translation.tr("Text shared"), true);
            }
        }
    }

    property var filePickerDevice: null

    function pickAndSendFiles(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        if (filePickerProc.running) return;
        root.lastActionError = "";
        root.filePickerDevice = d;
        filePickerProc.running = true;
    }

    Process {
        id: filePickerProc
        command: ["kdialog", "--getopenfilename", Quickshell.env("HOME") ?? "", "--multiple"]
        stdout: StdioCollector {
            id: filePickerOut
        }
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            const urls = root.pickedFileUrls(filePickerOut.text);
            const d = root.filePickerDevice;
            root.filePickerDevice = null;
            if (urls.length === 0) return;
            root.shareUrls(d, urls);
            root.actionFeedback(urls.length === 1
                ? Translation.tr("Sending file…")
                : Translation.tr("Sending %1 files…").arg(String(urls.length)), true);
        }
    }

    property bool sftpMounted: false
    property string sftpBrowseDeviceId: ""
    property int sftpMountAttempts: 0
    readonly property int sftpMountAttemptCeiling: 10

    function browseFiles(device: var): void {
        const d = device ?? root.activeDevice;
        if (!d || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        root.lastActionError = "";
        root.sftpBrowseDeviceId = d.id;
        root.sftpMountAttempts = 0;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}/sftp`, "org.kde.kdeconnect.device.sftp", "mount", []));
        root.actionFeedback(Translation.tr("Mounting phone storage…"), true);
        sftpMountWait.restart();
    }

    function pollSftpMount(): void {
        const id = root.sftpBrowseDeviceId;
        if (!root.validDeviceId(id)) return;
        const sftpPath = `/modules/kdeconnect/devices/${id}/sftp`;
        root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", sftpPath, "org.kde.kdeconnect.device.sftp", "isMounted", []), mountedText => {
            root.sftpMounted = root.parseBusctlReply(mountedText)?.[0] === true;
            if (!root.sftpMounted) {
                if (++root.sftpMountAttempts < root.sftpMountAttemptCeiling) sftpMountWait.restart();
                else root.reportFailure(Translation.tr("Phone storage did not mount"));
                return;
            }
            root.enqueue(root.busctlCall("org.kde.kdeconnect.daemon", sftpPath, "org.kde.kdeconnect.device.sftp", "mountPoint", []), pointText => {
                const mount = root.parseBusctlReply(pointText)?.[0];
                if (typeof mount !== "string" || mount.length === 0) {
                    root.reportFailure(Translation.tr("Phone storage has no mount point"));
                    return;
                }
                storageProbe.mount = mount;
                storageProbe.exec(["test", "-d", root.sftpStoragePath(mount)]);
            });
        });
    }

    Timer {
        id: sftpMountWait
        interval: 600
        onTriggered: root.pollSftpMount()
    }

    Process {
        id: storageProbe
        property string mount: ""
        onExited: (exitCode, exitStatus) => {
            Quickshell.execDetached(["xdg-open", root.sftpBrowseTarget(storageProbe.mount, exitCode === 0)]);
        }
    }

    function selectDevice(id: var): void {
        if (!root.validDeviceId(id) || !Persistent.ready) return;
        Persistent.states.phone.activeDeviceId = id;
        Persistent.states.phone.recentDeviceIds = root.recentDeviceIdsAfterSelect(Persistent.states.phone.recentDeviceIds, id, 5);
    }

    function acceptPairing(device: var): void {
        const d = device ?? null;
        if (!d || !d.hasPairingRequest || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}`, "org.kde.kdeconnect.device", "acceptPairing", []));
    }

    function cancelPairing(device: var): void {
        const d = device ?? null;
        if (!d || !d.hasPairingRequest || root.backend !== "kdeconnect" || !root.validDeviceId(d.id)) return;
        root.runAction(root.busctlCall("org.kde.kdeconnect.daemon", `/modules/kdeconnect/devices/${d.id}`, "org.kde.kdeconnect.device", "cancelPairing", []));
    }

    property var actionQueue: []

    function runAction(argv: var): void {
        root.actionQueue.push(argv);
        root.pumpActions();
    }

    function pumpActions(): void {
        if (actionProc.running || root.actionQueue.length === 0) return;
        actionProc.exec(root.actionQueue.shift());
    }

    Process {
        id: actionProc
        environment: ({
            LANG: "C",
            LC_ALL: "C"
        })
        stderr: StdioCollector {
            id: actionErr
        }
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0) {
                const message = actionErr.text.trim() || Translation.tr("Phone Connect command failed");
                root.reportFailure(message);
                Quickshell.execDetached(["notify-send",
                    Translation.tr("Phone Connect"),
                    message,
                    "-a", "Shell"
                ]);
            }
            root.pumpActions();
        }
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
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            const callback = root.activeCallback;
            root.activeCallback = null;
            callback?.(busOut.text);
            root.pump();
        }
    }

    onEnableServiceChanged: {
        if (!root.enableService) {
            root.callQueue = [];
            root.activeCallback = null;
            root.stopMonitor();
            root.applyBackend("none");
        } else if (root.installed) {
            root.refresh();
        }
    }

    Process {
        id: whichProc
        running: root.enableService
        command: ["sh", "-c", "command -v busctl"]
        onExited: (exitCode, exitStatus) => {
            root.installed = (exitCode === 0);
            if (root.installed) root.refresh();
        }
    }

    readonly property int reconcileInterval: Math.max(root.pollInterval * 6, 60000)

    Timer {
        interval: root.monitorLive ? root.reconcileInterval : root.pollInterval
        running: root.enableService && root.installed
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }
}
