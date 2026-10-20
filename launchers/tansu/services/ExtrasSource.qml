import Quickshell
import Quickshell.Io
import Quickshell.Bluetooth
import QtQuick
import shell.services as Ryoku
import "../modules/common/functions/Extras.js" as X
import "../modules/common"
import "."

// The system side of the launcher extras -- what AppSource.qml is to apps.
// Overview.qml stays UI; it hands this file the search box's text and reads
// back what the box is asking for (`mode`) plus everything the cards show.
//
//   mode "calc"    calculator     (CalculatorCard.qml, all maths in Calc.js)
//   mode "clip"    clipboard      (ClipboardCard.qml, needs cliphist + wl-clipboard)
//   mode "color"   colour         (ColorCard.qml, `hyprpicker` for the eyedropper)
//   mode "emoji"   emoji picker   (EmojiCard.qml, data in Emoji.js)
//   mode "web"     browser-style web search (WebCard.qml, opens with xdg-open)
//   mode "shell"   a command to run (a row in the results list)
//   mode ""        nothing special -- apps (and any matching actions) as usual
//
// Everything degrades quietly: a missing tool just leaves its card saying so.
Scope {
    id: root

    property string query: ""

    property bool active: false

    property bool webSuggestions: SettingsService.flag("launcher.webSuggestions")

    // Start `wl-paste --watch cliphist store` ourselves so history is
    // collected from the moment the shell starts. Turn off if your Hyprland
    // config already runs it (harmless if both run -- cliphist de-duplicates
    // -- but pointless).
    property bool runClipboardWatcher: SettingsService.flag("launcher.clipboard")

    readonly property var routed: X.route(root.query)
    readonly property string mode: routed.mode
    readonly property string arg: routed.arg
    readonly property string prefix: routed.prefix
    readonly property bool terminalCommand: routed.terminal

    // The web card's engine: what the trigger picked, unless you changed it
    // with Tab / a chip. Typing a different trigger resets it.
    property int engineOverride: -1
    readonly property int engine: engineOverride >= 0 ? engineOverride : routed.engine
    onModeChanged: engineOverride = -1
    readonly property var engines: X.ENGINES

    function cycleEngine(step) {
        engineOverride = (engine + step + X.ENGINES.length) % X.ENGINES.length
    }

    readonly property var listEntries: {
        const out = []
        if (root.mode === "shell") {
            const cmd = root.arg.trim()
            out.push({
                isAction: true, id: "shell", kind: "shell",
                title: cmd === "" ? (root.terminalCommand ? "Run in a terminal" : "Run a command") : cmd,
                sub: cmd === ""
                    ? "Type a command \u2014 > runs in the background, $ opens a terminal"
                    : (root.terminalCommand ? "Runs in a terminal that stays open" : "Runs in the background; output comes back as a notification"),
                glyph: root.terminalCommand ? "terminal" : "play_arrow",
                command: cmd, terminal: root.terminalCommand, confirm: false
            })
        }
        return out
    }

    readonly property var actionMatches: root.mode === "" ? X.matchActions(root.query) : []

    function actionEntry(a) {
        return {
            isAction: true, id: a.id, kind: "action",
            title: a.title, sub: a.sub, glyph: a.glyph,
            confirm: a.confirm === true, def: a
        }
    }

    signal wallpapersRequested()

    function runLater(fn, delaySeconds) {
        afterLeave.stop()
        afterLeave.fn = fn
        afterLeave.interval = Math.max(0, Math.round((delaySeconds ?? 0.25) * 1000))
        afterLeave.restart()
    }

    Timer {
        id: afterLeave
        property var fn: null
        onTriggered: {
            const f = afterLeave.fn
            afterLeave.fn = null
            if (f)
                f()
        }
    }

    function run(entry) {
        if (!entry)
            return
        if (entry.kind === "shell") {
            if (entry.command === "")
                return
            root.spawn(entry.terminal ? X.terminalArgv(entry.command) : X.backgroundArgv(entry.command), 0.2)
            return
        }
        const a = entry.def
        if (!a)
            return
        // Ryoku's own backends where one exists.
        if (a.session) {
            root.runLater(() => Ryoku.SessionActions.run(a.session), a.delay)
        } else if (a.network === "wifi") {
            root.runLater(() => Ryoku.Network.setWifiEnabled(!Ryoku.Network.wifiRadio), a.delay)
        } else if (a.network === "bluetooth") {
            root.runLater(() => {
                const adapter = Bluetooth.defaultAdapter
                if (adapter)
                    adapter.enabled = !adapter.enabled
            }, a.delay)
        } else if (a.special === "wallpapers") {
            root.wallpapersRequested()
        } else if (a.special === "nightlight") {
            root.runLater(() => Ryoku.Nightlight.toggle(), a.delay)
        } else if (a.argv) {
            root.spawn(a.argv, a.delay ?? 0.25)
        }
    }

    function spawn(argv, delaySeconds) {
        Quickshell.execDetached(["sh", "-c", "sleep \"$1\"; shift; exec \"$@\"", "sh", String(delaySeconds)].concat(argv))
    }

    function copyText(text) {
        Quickshell.execDetached(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", text])
    }

    function openUrl(url) {
        Quickshell.execDetached(["xdg-open", url])
    }

    function typeText(text) {
        Quickshell.execDetached(["sh", "-c", "sleep 0.35; command -v wtype >/dev/null && wtype -- \"$1\"", "sh", text])
    }

    property var suggestions: []
    property string suggestionsFor: ""

    readonly property string webQuery: root.mode === "web" ? root.arg.trim() : ""

    Timer {
        id: suggestDebounce
        interval: 220
        onTriggered: {
            if (root.webQuery === "" || X.looksLikeUrl(root.webQuery)) {
                root.suggestions = []
                return
            }
            suggestProc.wanted = root.webQuery
            suggestProc.running = false
            suggestProc.running = true
        }
    }

    onWebQueryChanged: {
        if (!root.webSuggestions || root.webQuery === "") {
            root.suggestions = []
            suggestDebounce.stop()
            return
        }
        suggestDebounce.restart()
    }

    Process {
        id: suggestProc
        property string wanted: ""
        command: ["curl", "-s", "--max-time", "3", "-G", "https://duckduckgo.com/ac/",
                  "--data-urlencode", "q=" + wanted, "--data-urlencode", "type=list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (suggestProc.wanted !== root.webQuery)
                    return
                try {
                    const json = JSON.parse(text)
                    root.suggestions = (json[1] || []).slice(0, 6)
                    root.suggestionsFor = suggestProc.wanted
                } catch (e) {
                    root.suggestions = []
                }
            }
        }
    }

    property bool clipAvailable: false
    property var clipEntries: []
    property string clipFull: ""
    property string clipImage: ""
    property string clipSelectedId: ""
    property string clipRaw: ""

    Process {
        running: true
        command: ["sh", "-c", "command -v cliphist >/dev/null && command -v wl-copy >/dev/null"]
        onExited: (code, status) => root.clipAvailable = (code === 0)
    }

    Process {
        running: root.runClipboardWatcher && root.clipAvailable
        command: ["wl-paste", "--type", "text", "--watch", "cliphist", "store"]
    }
    Process {
        running: root.runClipboardWatcher && root.clipAvailable
        command: ["wl-paste", "--type", "image", "--watch", "cliphist", "store"]
    }

    function refreshClip() {
        if (!clipAvailable || clipList.running)
            return
        clipList.running = true
    }

    Process {
        id: clipList
        command: ["sh", "-c", "cliphist -preview-width 500 list 2>/dev/null || cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text === root.clipRaw)
                    return
                root.clipRaw = text
                root.clipEntries = X.parseClipList(text).slice(0, 300)
            }
        }
    }

    Timer {
        interval: 1500
        repeat: true
        running: root.active && root.mode === "clip"
        triggeredOnStart: true
        onTriggered: root.refreshClip()
    }

    function dropClipTemp() {
        Quickshell.execDetached(["sh", "-c", "rm -f \"${XDG_RUNTIME_DIR:-/tmp}\"/tansu-clip-*"])
    }

    Component.onCompleted: root.dropClipTemp()

    // Load the full text (or image) for the highlighted entry. `clipLoadedId` is the
    // entry whose full contents are in clipFull / clipImage now; until it matches the
    // pick, the card knows it is still waiting (and must not pass the short preview
    // off as the whole text). If nothing comes in time, `clipFailed` says so.
    property string clipLoadedId: ""
    property bool clipFailed: false
    property string clipError: ""
    property var clipPending: null
    readonly property bool clipLoading: clipSelectedId !== "" && clipLoadedId !== clipSelectedId && !clipFailed

    // Latest pick wins. A Process that is still running ignores `running = true`
    // (setting it false only sends SIGTERM and the process is "running" until it has
    // really exited), so the old `running = false; running = true` pair silently
    // did nothing while a decode was in flight and the new pick never loaded.
    // Instead: remember the pick, stop the old decode, and start the new one from
    // onRunningChanged once the old one is gone.
    function startClipDecode() {
        const e = root.clipPending
        if (!e)
            return
        root.clipPending = null
        clipDecode.entry = e
        clipDecode.running = true
    }

    function clipDecodeEnded() {
        if (root.clipPending) {
            root.startClipDecode()
            return
        }
        if (root.clipSelectedId !== "" && root.clipLoadedId !== root.clipSelectedId)
            root.clipFailed = true
    }

    function selectClip(entry) {
        if (!entry) {
            if (root.clipImage !== "")
                root.dropClipTemp()
            root.clipSelectedId = ""
            root.clipLoadedId = ""
            root.clipFailed = false
            root.clipError = ""
            root.clipFull = ""
            root.clipImage = ""
            root.clipPending = null
            if (clipDecode.running)
                clipDecode.running = false
            clipGiveUp.stop()
            return
        }
        if (root.clipSelectedId === entry.id && (root.clipLoadedId === entry.id || root.clipLoading))
            return
        root.clipSelectedId = entry.id
        root.clipLoadedId = ""
        root.clipFailed = false
        root.clipError = ""
        root.clipFull = ""
        root.clipImage = ""
        root.clipPending = entry
        if (clipDecode.running)
            clipDecode.running = false
        else
            root.startClipDecode()
        clipGiveUp.restart()
    }

    Timer {
        id: clipGiveUp
        interval: 10000
        onTriggered: {
            if (root.clipSelectedId !== "" && root.clipLoadedId !== root.clipSelectedId)
                root.clipFailed = true
        }
    }

    readonly property string clipImageScript: [
        'd="${XDG_RUNTIME_DIR:-/tmp}"; rm -f "$d"/tansu-clip-*; f="$d/tansu-clip-$1"',
        'cliphist decode "$1" > "$f" && [ -s "$f" ] || exit 1',
        't=$(file -b --mime-type "$f" 2>/dev/null)',
        'case "$t" in image/png|image/jpeg|image/gif|image/bmp) ;; *)',
        '  for c in magick convert; do',
        '    if command -v "$c" >/dev/null 2>&1 && "$c" "$f" "png:$f.png" 2>/dev/null && [ -s "$f.png" ]; then mv -f "$f.png" "$f"; break; fi',
        '  done;; esac',
        'rm -f "$f.png"',
        'printf %s "$f"'
    ].join("\n")

    // Every answer says which entry it is for (text: its id on the first line; image:
    // the id is in the file's name), and is only used while that entry is still the
    // pick. A decode that was stopped half way by the next pick can then never leave
    // its text (or a picture's path) in the wrong entry.
    Process {
        id: clipDecode
        property var entry: null
        command: entry === null ? ["true"]
            : (entry.image
                ? ["sh", "-c", clipImageScript, "sh", entry.id]
                : ["sh", "-c", "printf '%s\\n' \"$1\"; cliphist decode \"$1\"", "sh", entry.id])
        stdout: StdioCollector {
            onStreamFinished: {
                const sel = root.clipSelectedId
                if (sel === "")
                    return
                const nl = text.indexOf("\n")
                if (nl > 0 && text.slice(0, nl) === sel) {
                    root.clipFull = text.slice(nl + 1)
                    root.clipLoadedId = sel
                    root.clipFailed = false
                    return
                }
                if (text.endsWith("/tansu-clip-" + sel)) {
                    root.clipImage = "file://" + text
                    root.clipLoadedId = sel
                    root.clipFailed = false
                }
            }
        }
        stderr: StdioCollector {
            onStreamFinished: {
                if (clipDecode.entry && clipDecode.entry.id === root.clipSelectedId)
                    root.clipError = text.trim()
            }
        }
        onRunningChanged: {
            if (!running)
                root.clipDecodeEnded()
        }
    }

    function copyClip(entry) {
        if (!entry)
            return
        if (entry.image) {
            Quickshell.execDetached(["sh", "-c",
                "f=$(mktemp) && cliphist decode \"$1\" > \"$f\" && t=$(file -b --mime-type \"$f\" 2>/dev/null); "
                + "case \"$t\" in image/*) ;; *) t=image/png;; esac; wl-copy --type \"$t\" < \"$f\"; rm -f \"$f\"", "sh", entry.id])
            return
        }
        Quickshell.execDetached(["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", entry.id])
    }

    function deleteClip(entry) {
        if (!entry)
            return
        Quickshell.execDetached(["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "sh", entry.id])
        root.clipEntries = root.clipEntries.filter(e => e.id !== entry.id)
    }

    property var recentEmoji: []

    readonly property string stateScript: Directories.script("state/extras-state.sh")

    Process {
        running: true
        command: ["sh", root.stateScript, "load-emoji"]
        stdout: StdioCollector {
            onStreamFinished: root.recentEmoji = text.split("\n").filter(l => l.length > 0).slice(0, 32)
        }
    }

    function rememberEmoji(ch) {
        const next = [ch].concat(root.recentEmoji.filter(e => e !== ch)).slice(0, 32)
        root.recentEmoji = next
        Quickshell.execDetached(["sh", root.stateScript, "save-emoji"].concat(next))
    }

    signal colorPicked(string hex)

    function pickColor() {
        picker.running = false
        picker.running = true
    }

    Process {
        id: picker
        command: ["sh", "-c", "sleep 0.4; exec hyprpicker --format=hex"]
        stdout: StdioCollector {
            onStreamFinished: {
                const hex = text.trim()
                if (/^#[0-9a-fA-F]{6}$/.test(hex))
                    root.colorPicked(hex)
            }
        }
    }
}
