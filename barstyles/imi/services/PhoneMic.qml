pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import "../modules/common"

Singleton {
    id: root

    readonly property bool available: PhoneDeps.pactl && (PhoneDeps.scrcpy || PhoneDeps.droidcamCli)
    readonly property string preferredBackend: PhoneDeps.scrcpy ? "scrcpy" : (PhoneDeps.droidcamCli ? "droidcam" : "")
    readonly property bool deviceReachable: PhoneConnect.activeDevice?.reachable === true
    readonly property string activeDeviceId: String(PhoneConnect.activeDevice?.id ?? "")

    property bool connecting: false
    property bool active: false
    readonly property string state: root.stateFor(root.available, root.deviceReachable, root.connecting, root.active)

    property string backend: ""
    property bool muted: false
    property int gain: 100
    property bool isDefaultInput: false
    property string previousDefaultSource: ""
    property string pulseSource: ""
    property string activeMode: ""
    property string activeIp: ""
    property int activePort: 0
    property int sessionPid: 0
    property int startedAt: 0
    property string lastError: ""
    property bool userStopped: false
    property string swappedSink: Persistent.states.phone.mic.originalDefaultSink

    readonly property string sinkName: "DroidCam-Mic"
    readonly property string sessionScript: `${Directories.scriptPath}/phone/droidcam_session.sh`
    readonly property string statusScript: `${Directories.scriptPath}/phone/droidcam_status.sh`
    readonly property string setupScript: `${Directories.scriptPath}/phone/setup_droidcam_input.sh`
    readonly property string teardownScript: `${Directories.scriptPath}/phone/teardown_droidcam_input.sh`
    readonly property int connectTimeoutMs: 10000
    readonly property int verifyAfterMs: 5000
    readonly property int swapPollMs: 250
    readonly property int swapCeilingMs: 3000

    signal errorOccurred(string message)

    function stateFor(available: bool, reachable: bool, connecting: bool, active: bool): string {
        if (!available) return "unavailable";
        if (active) return "active";
        if (connecting) return "connecting";
        if (!reachable) return "offline";
        return "ready";
    }

    function sessionFor(backend: string): string {
        return backend === "scrcpy" ? "scrcpy-mic" : "audio";
    }

    function scrcpyMicArgs(targetArgs: var): var {
        return ["scrcpy", "--no-video", "--no-window", "--audio-source=mic", "--audio-buffer=50"]
            .concat(targetArgs ?? []);
    }

    function droidcamAudioArgs(mode: string, ip: string, port: int): var {
        const args = ["env", "PULSE_SINK=" + root.sinkName, "droidcam-cli", "-a", "-nocontrols"];
        if (mode === "usb") args.push("adb", String(port));
        else args.push(String(ip), String(port));
        return args;
    }

    function connectionPlan(conf: var, adbState: string, addresses: var): var {
        const c = conf ?? {};
        const port = Number(c.port) > 0 ? Number(c.port) : 4748;
        if (c.connection === "usb") return { mode: "usb", ip: "", port: port };
        const configured = String(c.wifiIp ?? "").trim();
        if (configured.length > 0) return { mode: "wifi", ip: configured, port: port };
        if (String(adbState ?? "").trim() === "device") return { mode: "usb", ip: "", port: port };
        for (let i = 0; i < (addresses?.length ?? 0); i++) {
            const address = String(addresses[i] ?? "").trim();
            if (address.length > 0) return { mode: "wifi", ip: address, port: port };
        }
        return { error: "Could not detect USB or Wi-Fi IP. Plug the phone in with USB debugging on, or set the phone's Wi-Fi IP from the DroidCam app in the microphone settings." };
    }

    function streamPresent(sinkInputsText: string): bool {
        return /scrcpy/i.test(sinkInputsText ?? "");
    }

    function parseStatus(text: string): var {
        try {
            const doc = JSON.parse((text ?? "").trim());
            if (!doc || typeof doc !== "object") return null;
            return {
                audioRunning: doc.audio_running === true,
                audioHasSinkInput: doc.audio_has_sink_input === true,
                audioSource: String(doc.audio_source ?? "")
            };
        } catch (e) {
            return null;
        }
    }

    function parseSessionStatus(text: string): var {
        try {
            const doc = JSON.parse((text ?? "").trim());
            if (!doc || typeof doc !== "object") return null;
            return {
                session: String(doc.session ?? ""),
                alive: doc.alive === true || doc.alive === "true",
                pid: parseInt(doc.pid) || 0,
                started: parseInt(doc.started) || 0,
                port: parseInt(doc.port) || 0,
                mode: String(doc.mode ?? ""),
                ip: String(doc.ip ?? "")
            };
        } catch (e) {
            return null;
        }
    }

    function restorePlan(defaultSink: string, savedSink: string, sessionAlive: bool): string {
        if (String(defaultSink ?? "").trim() !== root.sinkName) return "";
        if (sessionAlive) return "";
        const saved = String(savedSink ?? "").trim();
        return (saved.length > 0 && saved !== root.sinkName) ? saved : "@DEFAULT_SINK@";
    }

    function muteArgs(source: string, muted: bool): var {
        return ["pactl", "set-source-mute", source, muted ? "1" : "0"];
    }

    function gainArgs(source: string, percent: int): var {
        return ["pactl", "set-source-volume", source, String(Math.max(0, Math.min(200, percent))) + "%"];
    }

    function fail(message: string): void {
        root.connecting = false;
        root.active = false;
        root.lastError = message;
        root.errorOccurred(message);
        root.restoreDefaultSink();
        root.cleanupSession();
    }

    function refuse(message: string): void {
        root.lastError = message;
        root.errorOccurred(message);
    }

    function start(): void {
        if (!root.available || root.connecting || root.active) return;
        if (!root.deviceReachable) {
            root.refuse("No reachable phone - pair a device first");
            return;
        }
        root.connecting = true;
        root.userStopped = false;
        root.lastError = "";
        root.backend = root.preferredBackend;
        Persistent.states.phone.mic.lastBackend = root.backend;
        root.run(["pactl", "unload-module", "module-loopback"], null);
        root.run(["bash", root.setupScript], (text, code) => {
            if (!root.connecting) return;
            const source = (text ?? "").trim().split("\n")[0] ?? "";
            if (code !== 0 || source.length === 0) {
                root.fail("Failed to create the DroidCam-Mic null sink - pactl may not have permission");
                return;
            }
            root.pulseSource = source;
            if (root.backend === "scrcpy") root.startScrcpy();
            else root.startDroidcam();
        });
        root.armConnectTimers();
    }

    function startScrcpy(): void {
        root.run(["pactl", "get-default-sink"], (text, code) => {
            if (!root.connecting) return;
            const original = (text ?? "").trim();
            if (code !== 0 || original.length === 0) {
                root.fail("Could not read the current default audio sink - audio routing aborted");
                return;
            }
            if (original !== root.sinkName) root.rememberSwap(original);
            root.run(["pactl", "set-default-sink", root.sinkName], (t, c) => {
                if (!root.connecting) return;
                root.activeMode = "scrcpy";
                root.activeIp = "";
                root.activePort = 0;
                const target = PhoneScrcpy.targetArgs(Config.options.phone.scrcpy, PhoneConnect.activeDevice);
                root.run(["bash", root.sessionScript, "launch", "scrcpy-mic"].concat(root.scrcpyMicArgs(target)),
                    (out, rc) => {
                        if (!root.connecting) return;
                        root.sessionPid = parseInt(out) || 0;
                        root.armSwapRestore();
                        root.armVerify();
                    });
            });
        });
    }

    function startDroidcam(): void {
        const conf = Config.options.phone.microphone;
        const direct = root.connectionPlan(conf, "", []);
        if (!direct.error) {
            root.launchDroidcam(direct);
            return;
        }
        root.run(["adb", "get-state"], (text, code) => {
            if (!root.connecting) return;
            const plan = root.connectionPlan(conf, code === 0 ? text : "",
                PhoneConnect.activeDevice?.reachableAddresses ?? []);
            if (plan.error) {
                root.fail(plan.error);
                return;
            }
            root.launchDroidcam(plan);
        });
    }

    function launchDroidcam(plan: var): void {
        root.activeMode = plan.mode;
        root.activeIp = plan.ip;
        root.activePort = plan.port;
        Persistent.states.phone.mic.lastMode = plan.mode;
        Persistent.states.phone.mic.lastIp = plan.ip;
        Persistent.states.phone.mic.lastPort = plan.port;
        root.run(["bash", root.sessionScript, "launch", "audio"]
            .concat(root.droidcamAudioArgs(plan.mode, plan.ip, plan.port)), (out, rc) => {
                if (!root.connecting) return;
                if (rc !== 0) {
                    root.fail("DroidCam did not start - is the DroidCam app open on the phone?");
                    return;
                }
                root.sessionPid = parseInt(out) || 0;
                root.armVerify();
            });
    }

    function rememberSwap(original: string): void {
        root.swappedSink = original;
        Persistent.states.phone.mic.originalDefaultSink = original;
    }

    function restoreDefaultSink(): void {
        root.disarmSwapRestore();
        const original = root.swappedSink;
        if (!original) return;
        root.swappedSink = "";
        Persistent.states.phone.mic.originalDefaultSink = "";
        root.run(["pactl", "set-default-sink", original], null);
    }

    function pollSwap(): void {
        root.run(["pactl", "list", "sink-inputs"], (text, code) => {
            if (root.streamPresent(text)) root.restoreDefaultSink();
        });
    }

    function verify(): void {
        root.run(["bash", root.statusScript], (text, code) => {
            if (!root.connecting) return;
            const status = root.parseStatus(text);
            if (status && status.audioRunning && status.audioHasSinkInput) {
                root.becomeActive();
            } else if (status && status.audioRunning) {
                if (root.connectDeadlinePassed())
                    root.fail("The phone microphone started but no audio reached the DroidCam-Mic sink - another audio processor may have claimed the stream");
                else root.armVerifyRetry();
            } else {
                root.fail("Phone microphone process exited - check the phone connection and that USB or Wireless debugging is still on");
            }
        });
    }

    function becomeActive(): void {
        root.connecting = false;
        root.active = true;
        root.lastError = "";
        root.startedAt = Math.floor(Date.now() / 1000);
        root.disarmConnectTimers();
        root.restoreDefaultSink();
        root.applyInitialState();
        root.armWatchdog();
    }

    function applyInitialState(): void {
        const conf = Config.options.phone.microphone;
        root.muted = false;
        root.gain = Number(conf.micGain) > 0 ? Number(conf.micGain) : 100;
        if (root.gain !== 100) root.setGain(root.gain);
        if (conf.setAsDefault) root.setAsDefaultInput();
    }

    function adoptSession(status: var): void {
        root.backend = status.session === "scrcpy-mic" ? "scrcpy" : "droidcam";
        root.sessionPid = status.pid;
        root.startedAt = status.started;
        root.activeMode = root.backend === "scrcpy" ? "scrcpy" : status.mode;
        root.activeIp = status.ip;
        root.activePort = status.port;
        root.run(["bash", root.setupScript], (text, code) => {
            root.pulseSource = (text ?? "").trim().split("\n")[0] ?? "";
            root.connecting = false;
            root.active = true;
            root.lastError = "";
            root.armWatchdog();
        });
    }

    function reconcile(): void {
        root.run(["bash", root.sessionScript, "status", "scrcpy-mic"], (scrcpyText, c1) => {
            const scrcpyStatus = root.parseSessionStatus(scrcpyText);
            root.run(["bash", root.sessionScript, "status", "audio"], (audioText, c2) => {
                const audioStatus = root.parseSessionStatus(audioText);
                const live = (scrcpyStatus && scrcpyStatus.alive) ? scrcpyStatus
                    : ((audioStatus && audioStatus.alive) ? audioStatus : null);
                if (live && !root.active && !root.connecting) root.adoptSession(live);
                root.run(["pactl", "get-default-sink"], (sinkText, c3) => {
                    const target = root.restorePlan(sinkText, Persistent.states.phone.mic.originalDefaultSink, live !== null);
                    if (!target) return;
                    root.swappedSink = "";
                    Persistent.states.phone.mic.originalDefaultSink = "";
                    root.run(["pactl", "set-default-sink", target], null);
                });
            });
        });
    }

    function checkSession(): void {
        root.run(["bash", root.sessionScript, "status", root.sessionFor(root.backend)], (text, code) => {
            const status = root.parseSessionStatus(text);
            if (status && status.alive) return;
            if (root.active) {
                root.active = false;
                root.disarmWatchdog();
                if (!root.userStopped) root.fail("Microphone connection lost - the audio process exited");
            }
        });
    }

    function cleanupSession(): void {
        root.run(["bash", root.sessionScript, "stop", "audio"], null);
        root.run(["bash", root.sessionScript, "stop", "scrcpy-mic"], null);
        root.run(["pactl", "unload-module", "module-loopback"], null);
        root.run(["bash", root.teardownScript], null);
        root.pulseSource = "";
        root.sessionPid = 0;
        root.startedAt = 0;
    }

    function stop(): void {
        if (!root.connecting && !root.active) return;
        root.userStopped = true;
        root.disarmConnectTimers();
        root.disarmWatchdog();
        if (root.isDefaultInput) root.restoreDefaultInput();
        root.restoreDefaultSink();
        root.connecting = false;
        root.active = false;
        root.muted = false;
        root.cleanupSession();
    }

    function toggle(): void {
        if (root.connecting || root.active) root.stop();
        else root.start();
    }

    function toggleMute(): void {
        root.muted = !root.muted;
        if (root.active && root.pulseSource)
            root.run(root.muteArgs(root.pulseSource, root.muted), null);
    }

    function setGain(percent: int): void {
        root.gain = Math.max(0, Math.min(200, percent));
        Config.options.phone.microphone.micGain = root.gain;
        if (root.active && root.pulseSource)
            root.run(root.gainArgs(root.pulseSource, root.gain), null);
    }

    function setAsDefaultInput(): void {
        if (!root.active || !root.pulseSource || root.isDefaultInput) return;
        root.run(["pactl", "get-default-source"], (text, code) => {
            const previous = (text ?? "").trim();
            if (!root.active || !root.pulseSource) return;
            root.previousDefaultSource = previous;
            root.isDefaultInput = true;
            root.run(["pactl", "set-default-source", root.pulseSource], null);
        });
    }

    function restoreDefaultInput(): void {
        if (!root.isDefaultInput) return;
        root.isDefaultInput = false;
        if (root.previousDefaultSource)
            root.run(["pactl", "set-default-source", root.previousDefaultSource], null);
        root.previousDefaultSource = "";
    }


    property real connectStartedAt: 0

    function connectDeadlinePassed(): bool {
        return Date.now() - root.connectStartedAt >= root.connectTimeoutMs;
    }

    function armConnectTimers(): void {
        root.connectStartedAt = Date.now();
        failTimer.restart();
    }

    function disarmConnectTimers(): void {
        failTimer.stop();
        verifyTimer.stop();
        verifyRetryTimer.stop();
    }

    function armVerify(): void { verifyTimer.restart(); }
    function armVerifyRetry(): void { verifyRetryTimer.restart(); }

    function armSwapRestore(): void {
        swapTimer.elapsedMs = 0;
        swapTimer.restart();
    }

    function disarmSwapRestore(): void { swapTimer.stop(); }
    function armWatchdog(): void { watchdog.restart(); }
    function disarmWatchdog(): void { watchdog.stop(); }

    Timer {
        id: failTimer
        interval: root.connectTimeoutMs
        onTriggered: {
            if (!root.connecting) return;
            root.fail("Could not connect within " + Math.round(root.connectTimeoutMs / 1000)
                + "s - verify the phone is reachable and the DroidCam/scrcpy app is open");
        }
    }

    Timer {
        id: verifyTimer
        interval: root.verifyAfterMs
        onTriggered: if (root.connecting) root.verify()
    }

    Timer {
        id: verifyRetryTimer
        interval: 2000
        onTriggered: if (root.connecting) root.verify()
    }

    Timer {
        id: swapTimer
        property int elapsedMs: 0
        interval: root.swapPollMs
        repeat: true
        onTriggered: {
            swapTimer.elapsedMs += swapTimer.interval;
            if (swapTimer.elapsedMs >= root.swapCeilingMs) {
                swapTimer.stop();
                root.restoreDefaultSink();
                return;
            }
            root.pollSwap();
        }
    }

    Timer {
        id: watchdog
        interval: 5000
        repeat: true
        onTriggered: {
            if (!root.active) { watchdog.stop(); return; }
            root.checkSession();
        }
    }


    property var callQueue: []
    property var activeCallback: null

    function run(argv: var, callback: var): void {
        root.callQueue.push({ argv: argv, callback: callback });
        root.pump();
    }

    function pump(): void {
        if (cmdProc.running || root.callQueue.length === 0) return;
        const next = root.callQueue.shift();
        root.activeCallback = next.callback;
        cmdProc.exec(next.argv);
    }

    Process {
        id: cmdProc
        environment: ({ LANG: "C", LC_ALL: "C" })
        stdout: StdioCollector { id: cmdOut }
        stderr: StdioCollector {}
        onExited: (exitCode, exitStatus) => {
            const callback = root.activeCallback;
            root.activeCallback = null;
            callback?.(cmdOut.text, exitCode);
            root.pump();
        }
    }

    Component.onCompleted: root.reconcile()

    onActiveDeviceIdChanged: if (root.active || root.connecting) root.stop()
}
