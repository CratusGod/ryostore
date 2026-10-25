pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Ryoku.Ui.Singletons

// SiMOrchestrator — the name the face already speaks to, at rest.
//
// In Jurai shell this singleton was the court's living state: the
// core's pulse, the shroud's tor, the hunt's latency. The launcher
// carries none of that — the core did not cross. What the FACE
// reads from this name is kept whole and honest:
//
//   * her accents and the prismatic chain, with her own values —
//     the morph color still answers modality and mode, because
//     the Obelisk herself drives those;
//   * her usage memory (itemUseCounts / recordUsage), kept in
//     her own state file now, feeding her own ranking;
//   * recordKeystroke / apmHeat — her hands' tempo, measured
//     locally, decaying locally;
//   * runNativeCommand — a command the operator picked, run.
//
// Everything that was the core's telemetry rests at zero and is
// labelled resting. Nothing here pretends a mind is listening.
Singleton {
    id: root

    // ── Her accents (her own values, from the shell original) ────
    readonly property color accentCognitive:  "#7B2CBF"
    readonly property color accentSovereign:  "#FFB000"
    readonly property color accentSystem:     "#00FF41"
    readonly property color accentWater:      "#00B4D8"
    readonly property color accentForge:      "#FF4E00"
    readonly property color accentBreach:     "#f43f5e"
    readonly property color accentInferring:  "#00B4D8"
    readonly property color accentEye:        "#00C2FF"
    readonly property color accentBlade:      "#FF3CAC"
    readonly property color accentSage:       "#FFB300"
    readonly property color accentMirror:     "#C8B8FF"
    readonly property color accentPhantom:    "#B44FE8"
    readonly property color accentShroud:     "#00FFC8"
    readonly property color accentForgeFold:  "#FF6B35"

    readonly property var styleAccents: ({
        "sun":       "#f59e0b",
        "moon":      "#818cf8",
        "celestial": "#ffffff"
    })

    // ── Mode state — the face drives these, as she always did ────
    property string obeliskMode:      "cognitive"
    property string activeModality:   "cognitive"
    property string anticipatedStyle: ""
    property string breathingStyle:   "moon"
    property string lockedTarget:     ""

    readonly property color prismaticColor: {
        if (root.activeModality === "reflex")    return Qt.color("#f43f5e")
        if (root.activeModality === "sovereign") return Qt.color("#f59e0b")
        if (root.activeModality === "architect") return Qt.color("#a78bfa")
        // The breath she drives in tints her water (his word,
        // 2026-10-25): Sun amber, Moon indigo, Celestial white.
        if (root.driveMode === "sun")       return Qt.color("#f59e0b")
        if (root.driveMode === "celestial") return Qt.color("#ffffff")
        if (root.driveMode === "moon")      return Qt.color("#818cf8")
        if (root.obeliskMode === "tactical" || root.obeliskMode === "applet")
            return Qt.color("#9B1FA0")
        if (root.obeliskMode === "forge")   return Qt.color("#818cf8")
        if (root.obeliskMode === "system")  return Qt.color("#00FF41")
        if (root.obeliskMode === "breathing") {
            var s = root.styleAccents[root.breathingStyle]
            return s ? Qt.color(s) : Qt.color("#818cf8")
        }
        return Qt.color("#00B4D8") // cognitive cerulean, her default
    }

    // ── Resting telemetry (the core's wires, honestly idle) ──────
    property string daemonState: "resting"
    property real   sysCpu: 0
    property real   sysRam: 0
    property real   sysTemp: 0
    property string governorFrequency: "—"
    property real   egressPulse: 0
    property real   lastLatencyMs: 0
    property real   shroudTorPct: 0
    property real   breachPulse: 0
    property bool   totalStealthMode: false
    property bool   launcherInstanceActive: false
    property real   cursorX: 0.5
    property real   cursorY: 0.5

    // ── Her hands' tempo ─────────────────────────────────────────
    property real apmHeat: 0
    property int  _keystrokes: 0

    function recordKeystroke() {
        root._keystrokes++
        root.apmHeat = Math.min(100, root.apmHeat + 1.5)
    }
    Timer {
        interval: 600
        repeat: true
        running: root.apmHeat > 0
        onTriggered: root.apmHeat = Math.max(0, root.apmHeat - 3)
    }

    // ── Her usage memory — her own file, her own ranking ────────
    property var itemUseCounts: ({})

    function recordUsage(id) {
        if (!id)
            return
        var next = Object.assign({}, root.itemUseCounts)
        next[id] = (next[id] || 0) + 1
        root.itemUseCounts = next
        usageStore.setText(JSON.stringify(next))
    }

    FileView {
        id: usageStore
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ryoku/mandara-usage.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    // ── The Three Breaths — her driving mode (his word, ──────
    // 2026-10-25). Sun, Moon, Celestial: the three houses
    // everything in her fits into. The mode tints her water,
    // biases her ranking and names itself on her stamp; it
    // rides a file, like her usage memory, so she
    // wakes in the breath she slept in.
    property string driveMode: "moon"
    function setDriveMode(m) {
        if (m === "star") m = "celestial"
        if (m !== "sun" && m !== "moon" && m !== "celestial") return
        root.driveMode = m
        driveStore.setText(JSON.stringify({ "mode": m }))
    }

    FileView {
        id: driveStore
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ryoku/mandara-drive.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    // ── The Rashin road (his word, 2026-10-25) ──────────────────
    // Natural language the lens recognizes is redirected here:
    // the envelope hears the signal and opens Rashin chat —
    // the compass window, the local mind's new main window —
    // carrying the line as its seed.
    signal rashinRequested(string seed)
    function requestRashin(seed) { rashinRequested(seed || "") }

    Component.onCompleted: {
        var raw = usageStore.text()
        try {
            root.itemUseCounts = raw && raw.length ? JSON.parse(raw) : ({})
        } catch (e) {
            root.itemUseCounts = ({})
        }
        var draw = driveStore.text()
        try {
            var dm = draw && draw.length ? JSON.parse(draw).mode : ""
            if (dm === "sun" || dm === "moon" || dm === "celestial")
                root.driveMode = dm
        } catch (e3) {}
    }

    // ── Running what the operator picked ─────────────────────────
    function runNativeCommand(cmd) {
        if (!cmd)
            return
        Spawn.run(["sh", "-c", cmd])
    }
}
