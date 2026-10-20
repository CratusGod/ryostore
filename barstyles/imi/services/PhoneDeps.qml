pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool scrcpyPresent: false
    property bool adbPresent: false
    property bool droidcamCliPresent: false

    property string scrcpyRunError: ""
    property string adbRunError: ""
    property string droidcamCliRunError: ""

    readonly property bool scrcpy: root.scrcpyPresent && root.scrcpyRunError.length === 0
    readonly property bool adb: root.adbPresent && root.adbRunError.length === 0
    readonly property bool droidcamCli: root.droidcamCliPresent && root.droidcamCliRunError.length === 0

    property bool v4l2Ctl: false
    property bool pactl: false
    property bool mpv: false
    property bool ffplay: false
    property bool vlc: false
    property bool kdialog: false
    property bool wlPaste: false
    property bool avahiBrowse: false
    property bool v4l2loopbackLoaded: false
    property bool v4l2loopbackInstalled: false
    property string scrcpyVersion: ""
    property int scrcpyMajor: 0
    property int scrcpyMinor: 0
    property string distro: "unknown"

    property bool adbDevice: false

    readonly property bool appModeSupported: root.scrcpy && root.scrcpyMajor >= 4

    property int probesPending: 0
    property bool probed: false
    readonly property bool ready: root.probed && root.probesPending === 0

    readonly property int runProbeTimeoutMs: 5000
    readonly property int adbActionTimeoutMs: 30000

    function parseScrcpyVersion(line: string): var {
        const match = /^scrcpy\s+v?(\d+)\.(\d+)(?:\.(\d+))?/.exec((line ?? "").trim());
        if (!match) return null;
        return {
            major: parseInt(match[1]),
            minor: parseInt(match[2]),
            version: match[1] + "." + match[2] + (match[3] ? "." + match[3] : "")
        };
    }

    function parseDistro(text: string): string {
        for (const line of (text ?? "").split("\n")) {
            const file = line.trim();
            if (file === "/etc/arch-release") return "arch";
            if (file === "/etc/fedora-release") return "fedora";
            if (file === "/etc/debian_version") return "debian";
        }
        return "unknown";
    }

    function parseLsmod(text: string): bool {
        return (text ?? "").split("\n").some(line => /^v4l2loopback(\b|_)/.test(line.trim()));
    }

    function parseAdbDevices(text: string): bool {
        for (const raw of (text ?? "").split("\n")) {
            const line = raw.trim();
            if (line.length === 0) continue;
            if (line.indexOf("List of devices") === 0) continue;
            const parts = line.split(/\s+/);
            if (parts.length >= 2 && parts[1] === "device") return true;
        }
        return false;
    }

    function parseLoaderFailure(exitCode: int, stderrText: string): string {
        if (exitCode !== 127) return "";
        const match = /error while loading shared libraries:\s*([^\s:]+)/.exec(String(stderrText ?? ""));
        return match ? match[1] : "";
    }

    // Each hint goes through Ryoku's host seam, which installs the package under
    // this edition's own name (Arch, CachyOS, Fedora or Void), so one command
    // fits every machine.
    function dependency(key: string): var {
        const table = {
            "scrcpy": {
                name: Translation.tr("scrcpy"),
                description: Translation.tr("Mirrors your phone screen in a floating SDL window. The main binary for screen mirroring."),
                commands: {
                    ryoku: "sudo ryoku-host pkg install scrcpy"
                }
            },
            "android-tools": {
                name: Translation.tr("android-tools (adb)"),
                description: Translation.tr("Required for USB connection, quick actions (screenshot, power button) and opening apps from notifications."),
                commands: {
                    ryoku: "sudo ryoku-host pkg install android-tools"
                }
            },
            "droidcam-cli": {
                name: Translation.tr("DroidCam CLI"),
                description: Translation.tr("Connects to the DroidCam app on your phone and streams video to /dev/videoN"),
                commands: {
                    ryoku: "# DroidCam is not in Ryoku's package repositories; get it from:\n# https://www.dev47apps.com/droidcam/linux/"
                }
            },
            "v4l2loopback": {
                name: Translation.tr("v4l2loopback kernel module"),
                description: Translation.tr("Creates virtual /dev/videoN devices that DroidCam writes to. Without it, droidcam-cli has nowhere to stream."),
                commands: {
                    ryoku: "sudo ryoku-host pkg install v4l2loopback-dkms linux-headers\nsudo modprobe v4l2loopback\necho v4l2loopback | sudo tee /etc/modules-load.d/v4l2loopback.conf"
                }
            },
            "v4l-utils": {
                name: Translation.tr("v4l-utils (v4l2-ctl)"),
                description: Translation.tr("Recommended for device detection and live mirror/flip controls"),
                commands: {
                    ryoku: "sudo ryoku-host pkg install v4l-utils"
                }
            },
            "mpv": {
                name: Translation.tr("mpv (optional)"),
                description: Translation.tr("Recommended for the webcam preview window. Falls back to ffplay/vlc if absent."),
                commands: {
                    ryoku: "sudo ryoku-host pkg install mpv"
                }
            },
            "pactl": {
                name: Translation.tr("pactl (PulseAudio/PipeWire CLI)"),
                description: Translation.tr("Required for audio routing — creates a virtual null-sink that turns the phone mic stream into a recordable source."),
                commands: {
                    ryoku: "sudo ryoku-host pkg install libpulse"
                }
            },
            "audio-backend": {
                name: Translation.tr("scrcpy or DroidCam CLI"),
                description: Translation.tr("At least one audio backend is needed. scrcpy is preferred (no extra app on phone). DroidCam CLI is the fallback."),
                commands: {
                    ryoku: "# Option 1 (preferred):\nsudo ryoku-host pkg install scrcpy\n# Option 2: DroidCam, from https://www.dev47apps.com/droidcam/linux/"
                }
            }
        };
        const entry = table[key];
        if (!entry) return null;
        return { key: key, name: entry.name, description: entry.description, commands: entry.commands };
    }

    function brokenDependency(entry: var, missingLibrary: string): var {
        const library = String(missingLibrary ?? "");
        if (!entry || library.length === 0) return entry;
        return {
            key: entry.key,
            name: entry.name,
            commands: entry.commands,
            broken: true,
            missingLibrary: library,
            description: Translation.tr("Installed, but it cannot start: the dynamic loader cannot find %1. This package was built against an older library than the system now ships, so it needs rebuilding or reinstalling rather than installing.").arg(library)
        };
    }

    function missingDeps(feature: string, flags: var): var {
        const f = flags ?? {};
        const missing = [];
        const need = (key, present, brokenBy) => {
            if (present) return;
            missing.push(root.brokenDependency(root.dependency(key), brokenBy));
        };
        const scrcpyBroken = String(f.scrcpyRunError ?? "");
        const adbBroken = String(f.adbRunError ?? "");
        const droidcamBroken = String(f.droidcamCliRunError ?? "");
        if (feature === "mirror") {
            need("scrcpy", f.scrcpy === true, scrcpyBroken);
            need("android-tools", f.adb === true, adbBroken);
        } else if (feature === "webcam") {
            need("droidcam-cli", f.droidcamCli === true, droidcamBroken);
            need("v4l2loopback", f.v4l2loopbackLoaded === true || f.v4l2loopbackInstalled === true, "");
            need("v4l-utils", f.v4l2Ctl === true, "");
            need("mpv", f.mpv === true, "");
        } else if (feature === "microphone") {
            need("pactl", f.pactl === true, "");
            need("audio-backend", f.scrcpy === true || f.droidcamCli === true,
                 scrcpyBroken.length > 0 ? scrcpyBroken : droidcamBroken);
        }
        return missing;
    }


    function adbPairArgv(address: string, code: string): var {
        return ["adb", "pair", String(address ?? "").trim(), String(code ?? "").trim()];
    }

    function adbConnectArgv(address: string): var {
        return ["adb", "connect", String(address ?? "").trim()];
    }

    function avahiBrowseArgv(serviceType: string): var {
        return ["avahi-browse", "-rpt", String(serviceType ?? "")];
    }

    function parseAvahiRecords(text: string): var {
        const out = [];
        for (const raw of String(text ?? "").split("\n")) {
            const line = raw.trim();
            if (line.length === 0 || line.charAt(0) !== "=") continue;
            const parts = line.split(";");
            if (parts.length < 9) continue;
            const host = String(parts[7] ?? "").trim();
            const port = String(parts[8] ?? "").trim();
            if (host.length === 0) continue;
            if (!/^\d{1,5}$/.test(port)) continue;
            const number = parseInt(port);
            if (number < 1 || number > 65535) continue;
            out.push({ host: host, port: port, address: host + ":" + port });
        }
        return out;
    }

    function pickAvahiRecord(records: var, preferredHost: string): var {
        const list = records ?? [];
        const want = String(preferredHost ?? "").trim();
        if (want.length > 0)
            for (let i = 0; i < list.length; i++)
                if (String(list[i].host) === want) return list[i];
        return list.length > 0 ? list[0] : null;
    }

    function firstMeaningfulLine(text: string): string {
        for (const raw of String(text ?? "").split("\n")) {
            const line = raw.trim();
            if (line.length > 0) return line;
        }
        return "";
    }

    function parsePairResult(exitCode: int, out: string, err: string): var {
        const text = (String(out ?? "") + "\n" + String(err ?? "")).trim();
        return {
            ok: exitCode === 0 && /successfully paired/i.test(text),
            message: root.firstMeaningfulLine(text)
        };
    }

    function parseConnectResult(exitCode: int, out: string, err: string): var {
        const text = (String(out ?? "") + "\n" + String(err ?? "")).trim();
        return {
            ok: exitCode === 0 && /^(already )?connected to /im.test(text),
            message: root.firstMeaningfulLine(text)
        };
    }

    function normalizePairingCode(text: string): string {
        return String(text ?? "").replace(/\D/g, "").substring(0, 6);
    }

    function splitAddress(text: string): var {
        const raw = String(text ?? "").trim();
        if (raw.length === 0) return null;
        const index = raw.lastIndexOf(":");
        if (index < 0) return { host: raw, port: "" };
        const host = raw.substring(0, index).trim();
        const port = raw.substring(index + 1).trim();
        if (host.length === 0) return null;
        if (port.length === 0) return { host: host, port: "" };
        if (!/^\d{1,5}$/.test(port)) return null;
        const number = parseInt(port);
        if (number < 1 || number > 65535) return null;
        return { host: host, port: port };
    }

    function pairInputsReady(address: string, code: string): bool {
        const parts = root.splitAddress(address);
        return parts !== null && parts.port.length > 0
            && root.normalizePairingCode(code).length === 6;
    }

    function connectInputReady(address: string): bool {
        return root.splitAddress(address) !== null;
    }

    function flags(): var {
        return {
            scrcpy: root.scrcpy, adb: root.adb, droidcamCli: root.droidcamCli,
            scrcpyRunError: root.scrcpyRunError, adbRunError: root.adbRunError,
            droidcamCliRunError: root.droidcamCliRunError,
            v4l2Ctl: root.v4l2Ctl, pactl: root.pactl, mpv: root.mpv, ffplay: root.ffplay,
            vlc: root.vlc, kdialog: root.kdialog, wlPaste: root.wlPaste,
            v4l2loopbackLoaded: root.v4l2loopbackLoaded,
            v4l2loopbackInstalled: root.v4l2loopbackInstalled
        };
    }

    function missingFor(feature: string): var {
        return root.missingDeps(feature, root.flags());
    }

    function startProbe(probe: var): void {
        if (probe.running) return;
        root.probesPending++;
        probe.running = true;
    }

    function recheck(): void {
        for (const probe of [scrcpyProbe, adbProbe, droidcamProbe, v4l2CtlProbe, pactlProbe,
                             mpvProbe, ffplayProbe, vlcProbe, kdialogProbe, wlPasteProbe,
                             avahiBrowseProbe, lsmodProbe, modinfoProbe, distroProbe])
            root.startProbe(probe);
    }

    function refreshAdbDevices(): void {
        if (!root.adb) return;
        root.startProbe(adbDevicesProbe);
    }

    function probeAnswered(): void {
        root.probesPending = Math.max(0, root.probesPending - 1);
    }

    Component.onCompleted: root.probed = true


    property string pairState: "idle"
    property string pairMessage: ""
    property string connectState: "idle"
    property string connectMessage: ""

    function pairWireless(address: string, code: string): void {
        if (root.pairState === "busy") return;
        if (!root.adb) {
            root.pairState = "failed";
            root.pairMessage = Translation.tr("adb is not available on this machine.");
            return;
        }
        if (!root.pairInputsReady(address, code)) {
            root.pairState = "failed";
            root.pairMessage = Translation.tr("A pairing address needs a host and the port the phone shows, and the code is six digits.");
            return;
        }
        root.pairState = "busy";
        root.pairMessage = "";
        pairGuard.restart();
        pairProcess.exec(root.adbPairArgv(address, root.normalizePairingCode(code)));
    }

    function connectWireless(address: string): void {
        if (root.connectState === "busy") return;
        if (!root.adb) {
            root.connectState = "failed";
            root.connectMessage = Translation.tr("adb is not available on this machine.");
            return;
        }
        if (!root.connectInputReady(address)) {
            root.connectState = "failed";
            root.connectMessage = Translation.tr("A connect address needs a host, and the port the Wireless debugging screen shows.");
            return;
        }
        root.connectState = "busy";
        root.connectMessage = "";
        connectGuard.restart();
        connectProcess.exec(root.adbConnectArgv(address));
    }

    Process {
        id: pairProcess
        stdout: StdioCollector { id: pairOut }
        stderr: StdioCollector { id: pairErr }
        onExited: (exitCode, exitStatus) => {
            pairGuard.stop();
            const result = root.parsePairResult(exitCode, pairOut.text, pairErr.text);
            root.pairState = result.ok ? "ok" : "failed";
            root.pairMessage = result.message;
        }
    }

    Process {
        id: connectProcess
        stdout: StdioCollector { id: connectOut }
        stderr: StdioCollector { id: connectErr }
        onExited: (exitCode, exitStatus) => {
            connectGuard.stop();
            const result = root.parseConnectResult(exitCode, connectOut.text, connectErr.text);
            root.connectState = result.ok ? "ok" : "failed";
            root.connectMessage = result.message;
            root.refreshAdbDevices();
        }
    }

    Timer {
        id: pairGuard
        interval: root.adbActionTimeoutMs
        onTriggered: {
            if (pairProcess.running) {
                pairProcess.signal(15);
                return;
            }
            if (root.pairState === "busy") {
                root.pairState = "failed";
                root.pairMessage = Translation.tr("adb did not answer.");
            }
        }
    }

    Timer {
        id: connectGuard
        interval: root.adbActionTimeoutMs
        onTriggered: {
            if (connectProcess.running) {
                connectProcess.signal(15);
                return;
            }
            if (root.connectState === "busy") {
                root.connectState = "failed";
                root.connectMessage = Translation.tr("adb did not answer.");
            }
        }
    }


    property string mdnsState: "idle"
    property string mdnsPairingAddress: ""
    property string mdnsConnectAddress: ""
    property int mdnsPending: 0

    function discoverWirelessPorts(): void {
        if (root.mdnsState === "searching") return;
        if (!root.avahiBrowse) {
            root.mdnsState = "unavailable";
            return;
        }
        root.mdnsState = "searching";
        root.mdnsPairingAddress = "";
        root.mdnsConnectAddress = "";
        root.mdnsPending = 2;
        mdnsGuard.restart();
        pairingBrowse.exec(root.avahiBrowseArgv("_adb-tls-pairing._tcp"));
        connectBrowse.exec(root.avahiBrowseArgv("_adb-tls-connect._tcp"));
    }

    function preferredWirelessHost(): string {
        const addresses = PhoneConnect.activeDevice?.reachableAddresses ?? [];
        for (let i = 0; i < addresses.length; i++) {
            const address = String(addresses[i] ?? "").trim();
            if (address.length > 0) return address;
        }
        return "";
    }

    function mdnsAnswered(): void {
        root.mdnsPending = Math.max(0, root.mdnsPending - 1);
        if (root.mdnsPending === 0) root.mdnsState = "done";
    }

    Process {
        id: pairingBrowse
        stdout: StdioCollector { id: pairingBrowseOut }
        stderr: StdioCollector {}
        onRunningChanged: if (!running) root.mdnsAnswered()
        onExited: (exitCode, exitStatus) => {
            const record = root.pickAvahiRecord(root.parseAvahiRecords(pairingBrowseOut.text),
                                                root.preferredWirelessHost());
            root.mdnsPairingAddress = record ? record.address : "";
        }
    }

    Process {
        id: connectBrowse
        stdout: StdioCollector { id: connectBrowseOut }
        stderr: StdioCollector {}
        onRunningChanged: if (!running) root.mdnsAnswered()
        onExited: (exitCode, exitStatus) => {
            const record = root.pickAvahiRecord(root.parseAvahiRecords(connectBrowseOut.text),
                                                root.preferredWirelessHost());
            root.mdnsConnectAddress = record ? record.address : "";
        }
    }

    Timer {
        id: mdnsGuard
        interval: root.runProbeTimeoutMs
        onTriggered: {
            if (pairingBrowse.running) pairingBrowse.signal(15);
            if (connectBrowse.running) connectBrowse.signal(15);
            if (root.mdnsState === "searching" && root.mdnsPending > 0) {
                root.mdnsPending = 0;
                root.mdnsState = "done";
            }
        }
    }

    Process {
        id: scrcpyProbe
        command: ["sh", "-c", "command -v scrcpy"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.scrcpyPresent = exitCode === 0;
            if (root.scrcpyPresent) {
                root.startProbe(versionProbe);
            } else {
                root.scrcpyRunError = "";
                root.scrcpyVersion = "";
                root.scrcpyMajor = 0;
                root.scrcpyMinor = 0;
            }
        }
    }

    Process {
        id: versionProbe
        command: ["scrcpy", "--version"]
        stdout: StdioCollector { id: versionOut }
        stderr: StdioCollector { id: versionErr }
        onRunningChanged: {
            if (running) scrcpyRunGuard.restart();
            else { scrcpyRunGuard.stop(); root.probeAnswered(); }
        }
        onExited: (exitCode, exitStatus) => {
            root.scrcpyRunError = root.parseLoaderFailure(exitCode, versionErr.text);
            const parsed = root.parseScrcpyVersion(versionOut.text.split("\n")[0] ?? "");
            root.scrcpyVersion = parsed?.version ?? "";
            root.scrcpyMajor = parsed?.major ?? 0;
            root.scrcpyMinor = parsed?.minor ?? 0;
        }
    }

    Process {
        id: adbProbe
        command: ["sh", "-c", "command -v adb"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.adbPresent = exitCode === 0;
            if (root.adbPresent) {
                root.startProbe(adbRunProbe);
            } else {
                root.adbRunError = "";
                root.adbDevice = false;
            }
        }
    }

    Process {
        id: adbRunProbe
        command: ["adb", "--version"]
        stdout: StdioCollector {}
        stderr: StdioCollector { id: adbRunErr }
        onRunningChanged: {
            if (running) adbRunGuard.restart();
            else { adbRunGuard.stop(); root.probeAnswered(); }
        }
        onExited: (exitCode, exitStatus) => {
            root.adbRunError = root.parseLoaderFailure(exitCode, adbRunErr.text);
            if (root.adb) root.startProbe(adbDevicesProbe);
            else root.adbDevice = false;
        }
    }

    Process {
        id: adbDevicesProbe
        command: ["adb", "devices"]
        stdout: StdioCollector { id: adbDevicesOut }
        stderr: StdioCollector {}
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.adbDevice = exitCode === 0 && root.parseAdbDevices(adbDevicesOut.text);
        }
    }

    Process {
        id: droidcamProbe
        command: ["sh", "-c", "command -v droidcam-cli"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.droidcamCliPresent = exitCode === 0;
            if (root.droidcamCliPresent) root.startProbe(droidcamRunProbe);
            else root.droidcamCliRunError = "";
        }
    }

    Process {
        id: droidcamRunProbe
        command: ["droidcam-cli"]
        stdout: StdioCollector {}
        stderr: StdioCollector { id: droidcamRunErr }
        onRunningChanged: {
            if (running) droidcamRunGuard.restart();
            else { droidcamRunGuard.stop(); root.probeAnswered(); }
        }
        onExited: (exitCode, exitStatus) => {
            root.droidcamCliRunError = root.parseLoaderFailure(exitCode, droidcamRunErr.text);
        }
    }

    Timer {
        id: scrcpyRunGuard
        interval: root.runProbeTimeoutMs
        onTriggered: if (versionProbe.running) versionProbe.signal(15)
    }

    Timer {
        id: adbRunGuard
        interval: root.runProbeTimeoutMs
        onTriggered: if (adbRunProbe.running) adbRunProbe.signal(15)
    }

    Timer {
        id: droidcamRunGuard
        interval: root.runProbeTimeoutMs
        onTriggered: if (droidcamRunProbe.running) droidcamRunProbe.signal(15)
    }

    Process {
        id: v4l2CtlProbe
        command: ["sh", "-c", "command -v v4l2-ctl"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.v4l2Ctl = exitCode === 0; }
    }

    Process {
        id: pactlProbe
        command: ["sh", "-c", "command -v pactl"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.pactl = exitCode === 0; }
    }

    Process {
        id: mpvProbe
        command: ["sh", "-c", "command -v mpv"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.mpv = exitCode === 0; }
    }

    Process {
        id: ffplayProbe
        command: ["sh", "-c", "command -v ffplay"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.ffplay = exitCode === 0; }
    }

    Process {
        id: vlcProbe
        command: ["sh", "-c", "command -v vlc"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.vlc = exitCode === 0; }
    }

    Process {
        id: kdialogProbe
        command: ["sh", "-c", "command -v kdialog"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.kdialog = exitCode === 0; }
    }

    Process {
        id: wlPasteProbe
        command: ["sh", "-c", "command -v wl-paste"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.wlPaste = exitCode === 0; }
    }

    Process {
        id: avahiBrowseProbe
        command: ["sh", "-c", "command -v avahi-browse"]
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => { root.avahiBrowse = exitCode === 0; }
    }

    Process {
        id: lsmodProbe
        command: ["lsmod"]
        stdout: StdioCollector { id: lsmodOut }
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.v4l2loopbackLoaded = exitCode === 0 && root.parseLsmod(lsmodOut.text);
        }
    }

    Process {
        id: modinfoProbe
        command: ["modinfo", "v4l2loopback"]
        stdout: StdioCollector {}
        stderr: StdioCollector {}
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.v4l2loopbackInstalled = exitCode === 0;
        }
    }

    Process {
        id: distroProbe
        command: ["sh", "-c", "for f in /etc/arch-release /etc/fedora-release /etc/debian_version; do [ -f \"$f\" ] && echo \"$f\"; done; true"]
        stdout: StdioCollector { id: distroOut }
        Component.onCompleted: root.startProbe(this)
        onRunningChanged: if (!running) root.probeAnswered()
        onExited: (exitCode, exitStatus) => {
            root.distro = root.parseDistro(distroOut.text);
        }
    }
}
