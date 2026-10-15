pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../modules/common"

Singleton {
    id: root

    readonly property bool available: PhoneDeps.scrcpy
    readonly property bool appModeSupported: PhoneDeps.appModeSupported
    readonly property var activeDevice: PhoneConnect.activeDevice
    readonly property string activeDeviceId: String(PhoneConnect.activeDevice?.id ?? "")

    property bool mirrorRunning: false
    property bool mirrorLaunching: false
    property string lastError: ""
    property string mirrorError: ""

    property var apps: []
    property bool appsLoading: false
    property string appsError: ""

    readonly property alias sessions: sessionsModel
    readonly property int sessionCount: sessionsModel.count

    readonly property var favorites: Config.options.phone.scrcpy.appMode.favoritePackages
    readonly property var recents: Persistent.states.phone.scrcpy.recentPackages
    readonly property int maxRecents: 20

    property string managerState: "idle"
    property int restartAttempts: 0
    readonly property int maxRestartAttempts: 5
    property var pendingMessages: []

    signal feedback(string message, bool ok)

    ListModel {
        id: sessionsModel
        dynamicRoles: true
    }

    function mirrorArgs(opts: var): var {
        const o = opts ?? {};
        const args = [];
        if (o.stayAwake) args.push("--stay-awake");
        if (o.turnScreenOff) args.push("--turn-screen-off");
        if (o.noPowerOn) args.push("--no-power-on");
        if (o.noAudio) args.push("--no-audio");
        if (o.showTouches) args.push("--show-touches");
        if (o.fullscreen) args.push("--fullscreen");
        if (o.alwaysOnTop) args.push("--always-on-top");
        if (Number(o.maxFps) > 0) args.push("--max-fps=" + Number(o.maxFps));
        if (typeof o.bitRate === "string" && o.bitRate.trim() !== "") args.push("--video-bit-rate=" + o.bitRate.trim());
        if (Number(o.maxSize) > 0) args.push("--max-size=" + Number(o.maxSize));
        if (Number(o.videoBuffer) > 0) args.push("--video-buffer=" + Number(o.videoBuffer));
        return args;
    }

    function appModeArgs(packageName: string, appOpts: var): var {
        const o = appOpts ?? {};
        const args = ["--start-app=" + packageName];
        if (o.flexDisplay) {
            const w = Number(o.displayWidth) > 0 ? Number(o.displayWidth) : 1280;
            const h = Number(o.displayHeight) > 0 ? Number(o.displayHeight) : 960;
            const density = Number(o.density) > 0 ? Number(o.density) : 160;
            args.push("--new-display=" + w + "x" + h + "/" + density);
            args.push("--flex-display");
            if (o.keepActive) args.push("--keep-active");
            if (o.systemDecorations === false) args.push("--no-vd-system-decorations");
        }
        return args;
    }

    function targetArgs(opts: var, device: var): var {
        const o = opts ?? {};
        if (!o.useWireless) return [];
        let ip = "";
        if (o.autoWirelessIp) {
            const addresses = device?.reachableAddresses ?? [];
            for (let i = 0; i < addresses.length; i++) {
                const address = String(addresses[i] ?? "").trim();
                if (address.length > 0) { ip = address; break; }
            }
        }
        if (!ip) ip = String(o.wirelessIp ?? "").trim();
        if (!ip) return [];
        const port = String(o.wirelessPort ?? "").trim() || "5555";
        return ["-s", ip.indexOf(":") >= 0 ? ip : ip + ":" + port];
    }

    function sessionIdFor(packageName: string): string {
        return "app:" + packageName;
    }

    function pushRecent(list: var, packageName: string, max: int): var {
        const out = [];
        for (let i = 0; i < (list?.length ?? 0); i++) {
            const entry = String(list[i]);
            if (entry !== packageName) out.push(entry);
        }
        out.unshift(packageName);
        return out.slice(0, max);
    }

    function toggleInList(list: var, packageName: string): var {
        const out = [];
        let found = false;
        for (let i = 0; i < (list?.length ?? 0); i++) {
            const entry = String(list[i]);
            if (entry === packageName) { found = true; continue; }
            out.push(entry);
        }
        if (!found) out.push(packageName);
        return out;
    }

    function isFavorite(packageName: string): bool {
        const list = root.favorites ?? [];
        for (let i = 0; i < list.length; i++)
            if (String(list[i]) === packageName) return true;
        return false;
    }

    function sessionIndex(id: string): int {
        for (let i = 0; i < sessionsModel.count; i++)
            if (sessionsModel.get(i).id === id) return i;
        return -1;
    }

    function isAppRunning(packageName: string): bool {
        return root.sessionIndex(root.sessionIdFor(packageName)) >= 0;
    }

    function backoffDelay(attempt: int): int {
        return Math.min(30000, 1000 * Math.pow(2, Math.max(1, attempt) - 1));
    }

    function managerWanted(): bool {
        return sessionsModel.count > 0 || root.mirrorLaunching || root.appsLoading
            || (root.pendingMessages?.length ?? 0) > 0;
    }

    function parseManagerLine(line: string): var {
        const trimmed = (line ?? "").trim();
        if (trimmed.length === 0) return null;
        try {
            const doc = JSON.parse(trimmed);
            return (doc && typeof doc === "object" && typeof doc.event === "string") ? doc : null;
        } catch (e) {
            return null;
        }
    }

    function applyEvent(msg: var): void {
        if (!msg) return;
        const id = String(msg.id ?? "");
        if (msg.event === "started") {
            const row = {
                id: id,
                type: String(msg.type ?? (id === "mirror" ? "mirror" : "app")),
                title: String(msg.title ?? ""),
                pid: Number(msg.pid ?? 0),
                package: id.startsWith("app:") ? id.substring(4) : "",
                startedAt: Date.now()
            };
            const index = root.sessionIndex(id);
            if (index >= 0) {
                for (const key in row) if (key !== "startedAt") sessionsModel.setProperty(index, key, row[key]);
            } else {
                sessionsModel.append(row);
            }
            if (id === "mirror") {
                if (msg.alreadyRunning === true) {
                    root.cancelMirrorSettle();
                    root.mirrorRunning = true;
                    root.mirrorLaunching = false;
                } else {
                    root.mirrorRunning = false;
                    root.mirrorLaunching = true;
                    root.armMirrorSettle();
                }
            }
        } else if (msg.event === "exited") {
            const index = root.sessionIndex(id);
            if (index >= 0) sessionsModel.remove(index);
            const failure = Number(msg.code ?? 0) !== 0 ? String(msg.error ?? "") : "";
            if (id === "mirror") {
                const wasLaunching = root.mirrorLaunching;
                root.cancelMirrorSettle();
                root.mirrorRunning = false;
                root.mirrorLaunching = false;
                root.mirrorError = failure.length > 0 ? failure
                    : (wasLaunching ? "scrcpy exited before the mirror window opened" : "");
            }
            if (failure.length > 0) {
                root.lastError = failure;
                root.feedback(root.lastError, false);
            }
        } else if (msg.event === "error") {
            if (id === "mirror") {
                root.cancelMirrorSettle();
                root.mirrorLaunching = false;
                root.mirrorRunning = false;
                root.mirrorError = String(msg.message ?? "scrcpy error");
            }
            root.lastError = String(msg.message ?? "scrcpy error");
            root.feedback(root.lastError, false);
        } else if (msg.event === "apps_list") {
            root.apps = Array.isArray(msg.apps) ? msg.apps : [];
            if (msg.cached !== true) {
                root.appsLoading = false;
                root.appsError = "";
            }
        } else if (msg.event === "apps_error") {
            root.appsLoading = false;
            root.appsError = String(msg.message ?? "Failed to list apps");
        }
    }

    function mirrorSettled(): void {
        if (root.sessionIndex("mirror") < 0) return;
        root.mirrorLaunching = false;
        root.mirrorRunning = true;
    }

    function handleLine(line: string): void {
        root.applyEvent(root.parseManagerLine(line));
    }

    function deviceId(): string {
        return root.activeDeviceId || "default";
    }

    function scrcpyTarget(): var {
        return root.targetArgs(Config.options.phone.scrcpy, root.activeDevice);
    }

    function launchMirror(): void {
        if (!root.available) {
            root.lastError = "scrcpy is not installed";
            return;
        }
        if (root.mirrorRunning) {
            root.focusMirror();
            return;
        }
        if (root.mirrorLaunching) return;
        root.mirrorLaunching = true;
        root.lastError = "";
        root.mirrorError = "";
        root.send({
            cmd: "launch", id: "mirror", type: "mirror",
            target_args: root.scrcpyTarget(),
            extra_args: root.mirrorArgs(Config.options.phone.scrcpy)
        });
    }

    function stopMirror(): void {
        root.send({ cmd: "stop", id: "mirror" });
    }

    function focusMirror(): void {
        root.send({ cmd: "focus", id: "mirror" });
    }

    function refreshApps(): void {
        if (!root.appModeSupported) return;
        root.appsLoading = true;
        root.appsError = "";
        root.send({ cmd: "list_apps", target_args: root.scrcpyTarget(), deviceId: root.deviceId() });
    }

    function launchApp(packageName: string): void {
        if (!packageName) return;
        if (!root.appModeSupported) {
            root.lastError = "scrcpy 4.0+ is required for App Mode";
            root.feedback(root.lastError, false);
            return;
        }
        if (root.isAppRunning(packageName)) {
            root.focusApp(packageName);
            return;
        }
        root.send({
            cmd: "launch", id: root.sessionIdFor(packageName), type: "app",
            target_args: root.scrcpyTarget(),
            extra_args: root.appModeArgs(packageName, Config.options.phone.scrcpy.appMode)
        });
        Persistent.states.phone.scrcpy.recentPackages =
            root.pushRecent(Persistent.states.phone.scrcpy.recentPackages, packageName, root.maxRecents);
    }

    function stopApp(packageName: string): void {
        if (!packageName) return;
        root.send({ cmd: "stop", id: root.sessionIdFor(packageName) });
    }

    function focusApp(packageName: string): void {
        if (!packageName) return;
        root.send({ cmd: "focus", id: root.sessionIdFor(packageName) });
    }

    function stopAllApps(): void {
        root.send({ cmd: "stop_all" });
    }

    function toggleFavorite(packageName: string): void {
        if (!packageName) return;
        Config.options.phone.scrcpy.appMode.favoritePackages =
            root.toggleInList(Config.options.phone.scrcpy.appMode.favoritePackages, packageName);
    }


    readonly property int mirrorSettleMs: 1500

    function armMirrorSettle(): void {
        mirrorSettleTimer.restart();
    }

    function cancelMirrorSettle(): void {
        mirrorSettleTimer.stop();
    }

    Timer {
        id: mirrorSettleTimer
        interval: root.mirrorSettleMs
        onTriggered: root.mirrorSettled()
    }


    function send(message: var): void {
        managerIdleTimer.restart();
        if (!manager.running) {
            root.pendingMessages = root.pendingMessages.concat([message]);
            root.startManager(true);
            return;
        }
        manager.write(JSON.stringify(message) + "\n");
    }

    function startManager(manual: bool): void {
        if (manager.running) return;
        if (manual) root.restartAttempts = 0;
        restartTimer.stop();
        root.managerState = "starting";
        manager.running = true;
    }

    function flushPending(): void {
        const queued = root.pendingMessages;
        root.pendingMessages = [];
        for (const message of queued)
            manager.write(JSON.stringify(message) + "\n");
    }

    function stopManager(): void {
        if (!manager.running) return;
        root.managerState = "idle";
        manager.running = false;
    }

    function clearLive(): void {
        root.cancelMirrorSettle();
        sessionsModel.clear();
        root.mirrorRunning = false;
        root.mirrorLaunching = false;
        root.appsLoading = false;
    }

    onSessionCountChanged: managerIdleTimer.restart()
    onAppsLoadingChanged: managerIdleTimer.restart()
    onMirrorLaunchingChanged: managerIdleTimer.restart()

    Timer {
        id: managerIdleTimer
        interval: 10000
        onTriggered: {
            if (root.managerWanted()) {
                managerIdleTimer.restart();
                return;
            }
            root.stopManager();
        }
    }

    Timer {
        id: restartTimer
        onTriggered: root.startManager(false)
    }

    Process {
        id: manager
        command: ["python3", `${Directories.scriptPath}/phone/scrcpy_session_manager.py`]
        stdinEnabled: true
        onStarted: {
            root.managerState = "running";
            root.flushPending();
        }
        stdout: SplitParser { onRead: data => root.handleLine(data) }
        stderr: SplitParser { onRead: data => console.warn("[PhoneScrcpy]", data) }
        onExited: (exitCode, exitStatus) => {
            const wasDeliberate = root.managerState === "idle";
            root.clearLive();
            if (wasDeliberate || root.pendingMessages.length === 0) {
                root.managerState = "idle";
                return;
            }
            if (root.restartAttempts >= root.maxRestartAttempts) {
                root.managerState = "stopped";
                root.pendingMessages = [];
                root.lastError = "scrcpy session manager stopped after repeated failures";
                root.mirrorError = root.lastError;
                root.feedback(root.lastError, false);
                return;
            }
            root.restartAttempts++;
            root.managerState = "restarting";
            restartTimer.interval = root.backoffDelay(root.restartAttempts);
            restartTimer.restart();
        }
    }

    onActiveDeviceIdChanged: {
        if (sessionsModel.count > 0) root.send({ cmd: "stop_all" });
    }
}
