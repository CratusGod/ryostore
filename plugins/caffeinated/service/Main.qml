pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// service/Main.qml holds Caffeinated's state. bin/caffeinated owns the logind
// inhibitor; this polls its status and runs on/off. The inhibitor lives outside the shell, so a shell reload keeps it.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    function setting(key, fallback) {
        const v = settings ? settings[key] : undefined;
        return v === undefined || v === null ? fallback : v;
    }

    readonly property string mode: setting("mode", "awake") === "lock" ? "lock" : "awake"
    readonly property bool lockOnEnable: setting("lockOnEnable", false)
    readonly property int batteryFloor: Math.max(0, Math.min(50, setting("batteryFloor", 15)))
    readonly property int poll: Math.max(2, Math.min(120, setting("poll", 10)))

    readonly property string script: pluginApi ? pluginApi.pluginDir + "/bin/caffeinated" : ""
    readonly property string stateDir: pluginApi ? pluginApi.stateDir : ""

    // Live state from `caffeinated status`.
    property bool on: false
    property string activeMode: ""
    property string reason: ""
    property var battery: null
    property bool onAc: true
    property bool busy: false
    property string error: ""

    function refresh() {
        if (!script || !stateDir || statusProc.running) return;
        // The timestamp re-stamps the attach mark: proof this shell is live.
        statusProc.command = [script, "status", stateDir, String(Date.now())];
        statusProc.running = true;
    }

    function run(argv, lockAfter) {
        if (!script || !stateDir || busy) return;
        busy = true;
        error = "";
        actionProc.lockAfter = lockAfter;
        actionProc.command = argv;
        actionProc.running = true;
    }

    function enable() {
        run([script, "on", stateDir, mode, String(batteryFloor)], mode === "lock" && lockOnEnable);
    }

    function disable() {
        run([script, "off", stateDir], false);
    }

    function toggle() {
        if (on) disable(); else enable();
    }

    function lockNow() {
        if (script) Quickshell.execDetached([script, "lock"]);
    }

    // A mode or floor change while on re-applies the inhibitor; the script
    // takes the new lock before dropping the old one, so there is no gap.
    function reapply() {
        if (on && !busy) run([script, "on", stateDir, mode, String(batteryFloor)], false);
    }
    onModeChanged: reapply()
    onBatteryFloorChanged: reapply()

    // Liveness marks: the inhibitor releases itself if the shell stays
    // detached (plugin disabled or removed) past a grace period. A reload
    // detaches and re-attaches within seconds, which keeps it.
    onStateDirChanged: if (script && stateDir) Quickshell.execDetached([script, "attach", stateDir, String(Date.now())])
    Component.onCompleted: {
        if (script && stateDir) Quickshell.execDetached([script, "attach", stateDir, String(Date.now())]);
        refresh();
    }
    Component.onDestruction: {
        if (script && stateDir) Quickshell.execDetached([script, "detach", stateDir, String(Date.now())]);
    }
    onScriptChanged: refresh()

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const st = JSON.parse(this.text);
                    svc.on = st.on;
                    svc.activeMode = st.mode;
                    svc.reason = st.reason;
                    svc.battery = st.battery;
                    svc.onAc = st.ac;
                } catch (e) {}
            }
        }
    }

    Process {
        id: actionProc
        property bool lockAfter: false
        stdout: StdioCollector { }
        stderr: StdioCollector { id: actionErr }
        onExited: (code) => {
            svc.busy = false;
            if (code !== 0) svc.error = actionErr.text.trim() || "caffeinated exited " + code;
            // Lock only once the inhibitor is confirmed.
            if (actionProc.lockAfter && code === 0)
                svc.lockNow();
            svc.refresh();
        }
    }

    Timer {
        interval: svc.poll * 1000
        running: true
        repeat: true
        onTriggered: svc.refresh()
    }
}
