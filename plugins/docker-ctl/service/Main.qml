pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io

// Polls the local Engine API and runs one container action at a time.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    function setting(key, fallback) {
        const v = settings ? settings[key] : undefined;
        return v === undefined || v === null ? fallback : v;
    }

    readonly property int poll: Math.max(2, Math.min(120, setting("poll", 5)))
    readonly property bool showStopped: setting("showStopped", true)
    readonly property string script: pluginApi ? pluginApi.pluginDir + "/bin/dockerctl" : ""

    property string daemon: "unknown"
    property bool reachable: false
    property var containers: []
    readonly property int runningCount: containers.filter(c => c.state === "running").length
    readonly property var shown: showStopped ? containers : containers.filter(c => c.state === "running")

    // The container being edited: `dockerctl inspect` output, or null.
    property var editing: null
    property string editingId: ""

    property bool busy: false
    property string busyId: ""
    property string busyAction: ""
    property string error: ""
    property string notice: ""

    function refresh() {
        if (!script || statusProc.running) return;
        statusProc.command = ["python3", "-I", script, "status"];
        statusProc.running = true;
    }

    function run(argv, id, after) {
        if (!script || busy) return;
        busy = true;
        busyId = id || "";
        busyAction = argv[0];
        error = "";
        notice = "";
        actionProc.after = after || null;
        actionProc.command = ["python3", "-I", script].concat(argv);
        actionProc.running = true;
    }

    function containerAction(action, id) { run([action, id], id); }


    function edit(id) {
        if (editingId === id) { closeEdit(); return; }
        editingId = id;
        editing = null;
        run(["inspect", id], id, function(text) {
            try { svc.editing = JSON.parse(text); } catch (e) { svc.error = "inspect: " + e; }
        });
    }

    function closeEdit() {
        editingId = "";
        editing = null;
    }

    // spec = { ports: [{container, hostIp, hostPort}], mounts: [{source, target, readOnly}] }
    function apply(id, spec) {
        run(["recreate", id, JSON.stringify(spec)], id, function() {
            svc.notice = "Recreated with the new ports and mounts.";
            svc.closeEdit();
        });
    }

    onScriptChanged: refresh()
    Component.onCompleted: refresh()

    Process {
        id: statusProc
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const st = JSON.parse(this.text);
                    svc.daemon = st.daemon;
                    svc.reachable = st.reachable;
                    svc.containers = st.containers;
                } catch (e) {}
            }
        }
    }

    Process {
        id: actionProc
        property var after: null
        stdout: StdioCollector { id: actionOut }
        stderr: StdioCollector { id: actionErr }
        onExited: (code) => {
            svc.busy = false;
            svc.busyId = "";
            svc.busyAction = "";
            if (code !== 0)
                svc.error = actionErr.text.trim() || "dockerctl exited " + code;
            else if (actionProc.after)
                actionProc.after(actionOut.text);
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
