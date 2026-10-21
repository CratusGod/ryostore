pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// service/Main.qml holds Keyboard Layouts' state. It finds the physical
// keyboards (USB and the laptop's own by default) by joining /proc/bus/input/devices with
// `hyprctl devices`, keeps a per-keyboard layout choice in stateDir, and applies
// it live through `hyprctl eval hl.device(...)`. A choice is re-applied whenever
// that keyboard shows up with a different layout: on replug, after a Hyprland
// config reload, and after a shell restart.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null

    function setting(key, fallback) {
        const v = settings ? settings[key] : undefined;
        return v === undefined || v === null ? fallback : v;
    }

    readonly property bool includeBluetooth: setting("includeBluetooth", false)
    readonly property bool includeBuiltin: setting("includeBuiltin", true)
    readonly property int poll: Math.max(1, Math.min(60, setting("poll", 3)))
    readonly property var pinned: String(setting("pinned", "us,gb")).split(",")
        .map(c => c.trim().toLowerCase()).filter(c => svc.validLayout(c))

    readonly property string stateDir: pluginApi ? pluginApi.stateDir : ""
    readonly property string storePath: stateDir ? stateDir + "/assignments.json" : ""

    // [{ name, label, kind, layout, keymap, main }]: the keyboards shown.
    property var keyboards: []
    // The layout code of the keyboard in use (Hyprland's main keyboard).
    property string current: ""
    // [{ code, desc }] from the xkb rules, sorted by description.
    property var layouts: []
    property var descs: ({})
    // Hyprland device name -> layout code. Persisted.
    property var assigned: ({})
    property bool storeLoaded: false
    // name -> code already sent this session; cleared when the keyboard goes
    // away or the config reloads, so a layout that will not take is not
    // re-sent on every poll.
    property var tried: ({})
    property bool busy: false
    property string error: ""

    property string procText: ""

    // Values that end up inside the Lua string passed to `hyprctl eval` are
    // checked against these, so no quote or backslash can ever reach it.
    function validLayout(code) { return /^[a-z][a-z0-9_]{0,15}$/.test(code); }
    function validName(name) { return /^[a-z0-9][a-z0-9._:()+\/-]{0,127}$/.test(name); }

    function describe(code) { return descs[code] || code.toUpperCase(); }

    function refresh() {
        if (procRead.running || devRead.running) return;
        procRead.running = true;
    }

    // Parse /proc/bus/input/devices into Hyprland name -> kind, keeping only
    // devices with letter keys (KEY_Q and KEY_A), so media-key and power-button
    // nodes of the same keyboard drop out.
    function physicalKeyboards(text) {
        const out = {};
        for (const block of text.split(/\n\s*\n/)) {
            const bus = (block.match(/^I: Bus=([0-9a-f]+)/m) || [])[1];
            const name = (block.match(/^N: Name="(.*)"$/m) || [])[1];
            const key = (block.match(/^B: KEY=(.*)$/m) || [])[1];
            if (!bus || !name || !key) continue;
            const words = key.trim().split(/\s+/);
            const low = parseInt(words[words.length - 1].slice(-8), 16);
            if (!((low >>> 16) & 1) || !((low >>> 30) & 1)) continue;
            const kind = bus === "0003" ? "usb" : bus === "0005" ? "bluetooth" : "builtin";
            out[name.toLowerCase().replace(/ /g, "-")] = { label: name, kind: kind };
        }
        return out;
    }

    function merge(devJson) {
        let devs;
        try { devs = JSON.parse(devJson).keyboards || []; } catch (e) { return; }
        const phys = physicalKeyboards(procText);
        const list = [];
        let cur = "";
        for (const d of devs) {
            const layouts = String(d.layout || "").split(",");
            const active = layouts[d.active_layout_index] || layouts[0] || "";
            if (d.main) cur = active;
            const p = phys[d.name];
            if (!p) continue;
            if (p.kind === "bluetooth" && !includeBluetooth) continue;
            if (p.kind === "builtin" && !includeBuiltin) continue;
            list.push({ name: d.name, label: p.label, kind: p.kind, layout: active,
                        keymap: d.active_keymap || "", main: !!d.main });
        }
        const present = {};
        for (const k of list) present[k.name] = true;
        for (const n in tried) if (!present[n]) delete tried[n];
        keyboards = list;
        current = cur;
        enforce();
    }

    // Re-apply every saved choice whose keyboard is present with another layout.
    function enforce() {
        if (!storeLoaded || busy) return;
        for (const k of keyboards) {
            const want = assigned[k.name];
            if (want && k.layout !== want && tried[k.name] !== want) {
                apply(k.name, want);
                return;
            }
        }
    }

    function apply(name, code) {
        if (!validName(name) || !validLayout(code)) {
            error = "Refusing an unexpected keyboard or layout name.";
            return;
        }
        tried[name] = code;
        busy = true;
        error = "";
        evalProc.command = ["hyprctl", "eval",
            'hl.device({ name = "' + name + '", kb_layout = "' + code + '", kb_variant = "" })'];
        evalProc.running = true;
    }

    function choose(name, code) {
        if (!validName(name) || !validLayout(code)) return;
        const next = Object.assign({}, assigned);
        next[name] = code;
        assigned = next;
        save();
        apply(name, code);
    }

    // Forget a choice and reload Hyprland, so the keyboard falls back to
    // whatever the Hyprland config says for it.
    function reset(name) {
        if (!(name in assigned)) return;
        const next = Object.assign({}, assigned);
        delete next[name];
        assigned = next;
        save();
        busy = true;
        evalProc.command = ["hyprctl", "reload"];
        evalProc.running = true;
    }

    function save() {
        if (storePath) store.setText(JSON.stringify(assigned, null, 2) + "\n");
    }

    onStateDirChanged: if (stateDir) Quickshell.execDetached(["mkdir", "-p", stateDir])
    Component.onCompleted: {
        if (stateDir) Quickshell.execDetached(["mkdir", "-p", stateDir]);
        rulesRead.running = true;
        refresh();
    }

    FileView {
        id: store
        path: svc.storePath
        printErrors: false
        atomicWrites: true
        onLoaded: {
            try {
                const obj = JSON.parse(text());
                const clean = {};
                for (const k in obj)
                    if (svc.validName(k) && svc.validLayout(obj[k])) clean[k] = obj[k];
                svc.assigned = clean;
            } catch (e) {}
            svc.storeLoaded = true;
            svc.enforce();
        }
        onLoadFailed: {
            svc.storeLoaded = true;
            svc.enforce();
        }
    }

    Process {
        id: procRead
        command: ["cat", "/proc/bus/input/devices"]
        stdout: StdioCollector {
            onStreamFinished: {
                svc.procText = this.text;
                devRead.running = true;
            }
        }
    }

    Process {
        id: devRead
        command: ["hyprctl", "-j", "devices"]
        stdout: StdioCollector {
            onStreamFinished: svc.merge(this.text)
        }
    }

    // The "! layout" section of the xkb rules: "  us   English (US)".
    Process {
        id: rulesRead
        command: ["cat", "/usr/share/X11/xkb/rules/evdev.lst"]
        stdout: StdioCollector {
            onStreamFinished: {
                const list = [];
                const descs = {};
                let inLayouts = false;
                for (const line of this.text.split("\n")) {
                    if (line.startsWith("!")) { inLayouts = line.trim() === "! layout"; continue; }
                    if (!inLayouts) continue;
                    const m = line.match(/^\s+(\S+)\s+(.+)$/);
                    // "custom" is xkb's placeholder for a user keymap file.
                    if (!m || m[1] === "custom" || !svc.validLayout(m[1])) continue;
                    list.push({ code: m[1], desc: m[2].trim() });
                    descs[m[1]] = m[2].trim();
                }
                list.sort((a, b) => a.desc.localeCompare(b.desc));
                svc.layouts = list;
                svc.descs = descs;
            }
        }
    }

    Process {
        id: evalProc
        stdout: StdioCollector { id: evalOut }
        stderr: StdioCollector { id: evalErr }
        onExited: (code) => {
            svc.busy = false;
            const out = evalOut.text.trim();
            if (code !== 0 || (out !== "" && out !== "ok"))
                svc.error = evalErr.text.trim() || out || "hyprctl exited " + code;
            svc.refresh();
        }
    }

    // activelayout fires on a layout switch; configreloaded drops runtime
    // device rules, so re-check at once instead of waiting for the poll.
    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded") svc.tried = {};
            if (event.name === "activelayout" || event.name === "configreloaded")
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
