pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// service/Main.qml: all logic, no UI.
//
//   setup check ─► setup (noCli | noJq | signedOut | signingIn | ready)
//   sources ──► rawState ──► claudeState ──► state machine ──► animation name
//   (watcher,     (merge)     (ClaudeState)    (table below)     (Widget/Sprite)
//    chat turn)
//
// The animation layer only ever sees `animState`; it does not know where Claude
// state came from. See docs/claude-integration.md and docs/first-run.md.
Item {
    id: svc

    property var pluginApi
    readonly property var settings: pluginApi ? pluginApi.pluginSettings : null
    readonly property bool ready: !!(pluginApi && pluginApi.pluginDir && pluginApi.pluginDir.length > 0)

    function _has(k) { return settings && settings[k] !== undefined && settings[k] !== null && settings[k] !== ""; }
    function _str(k, d) { return _has(k) ? String(settings[k]) : d; }
    function _int(k, d) { return _has(k) ? parseInt(settings[k]) : d; }
    function _bool(k, d) { return _has(k) ? settings[k] === true || settings[k] === "true" : d; }

    // ── settings (always behind a default) ─────────────────────────────────────
    readonly property int sleepAfter: Math.max(5, _int("sleepAfter", 120))
    readonly property int pixelScale: Math.max(1, Math.min(8, _int("pixelScale", 3)))
    readonly property bool bridgeEnabled: _str("bridge", "auto") !== "off"
    readonly property string chatCwd: _str("chatCwd", "")
    readonly property string permissionMode: _str("permissionMode", "default")
    readonly property string loginMethod: _str("loginMethod", "claudeai")
    readonly property bool debugOverlay: _bool("debugOverlay", false)
    readonly property string debugState: _str("debugState", "off")
    readonly property bool debugCycle: _bool("debugCycle", false)
    property bool systemReducedMotion: false
    readonly property bool reducedMotion: _bool("reducedMotion", false) || systemReducedMotion

    // ── season (setting "season": off | auto | christmas | halloween | ...) ─────
    // A seasonal outfit is its own sheet, assets/season-<id>.png, plus particles
    // (snow, bats, petals...) drawn by content/SeasonFx.qml. "auto" follows the
    // calendar; outside the windows below the plain companion stays.
    property date today: new Date()
    Timer {
        interval: 6 * 3600 * 1000
        running: svc.season === "auto" || svc.season === "auto-south"
        repeat: true
        onTriggered: svc.today = new Date()
    }
    readonly property string season: _str("season", "off")
    onSeasonChanged: today = new Date()
    readonly property string hemisphere: season === "auto-south" ? "south" : "north"
    function autoSeason(d) {
        const md = (d.getMonth() + 1) * 100 + d.getDate();     // 1016 = 16 Oct
        if (md >= 1201 || md <= 106) return "christmas";
        if (md >= 1015 && md <= 1102) return "halloween";
        if (hemisphere === "south") {
            if (md >= 107 && md <= 320) return "summer";
            if (md >= 321 && md <= 620) return "autumn";
            if ((md >= 923 && md <= 1014) || (md >= 1103 && md <= 1130)) return "spring";
            return "";
        }
        if (md >= 621 && md <= 922) return "summer";
        if (md >= 320 && md <= 430) return "spring";
        if ((md >= 923 && md <= 1014) || (md >= 1103 && md <= 1130)) return "autumn";
        return "";
    }
    readonly property string seasonNow: season === "off" ? "" : (season === "auto" || season === "auto-south") ? autoSeason(today) : season

    // the desktop host exposes no stateDir; "" lets the script use the XDG state dir
    function stateDirArg() { return (pluginApi && pluginApi.stateDir) ? String(pluginApi.stateDir) : ""; }
    function cmd(name) { return pluginApi.pluginDir + "/bin/" + name; }

    // ── first run: is Claude Code installed and signed in? ─────────────────────
    // setup: checking | noCli | noJq | signedOut | signingIn | ready
    property string setup: "checking"
    property string cliVersion: ""
    property bool hasInotify: true
    property string loginUrl: ""
    property string loginNote: ""            // last sign-in problem, shown in the panel
    property bool _loginCancelled: false
    readonly property bool setupNeeded: setup !== "ready" && setup !== "checking"

    property bool _recheckPending: false
    function recheck() {
        if (!ready) return;
        if (checkProc.running) { _recheckPending = true; return; }   // rerun when it ends: its output is stale
        checkProc.command = [cmd("companion-check")];
        checkProc.running = true;
    }
    function _onCheck(line) {
        if (_recheckPending) return;               // a newer check is queued
        let o = null;
        try { o = JSON.parse(line); } catch (e) { return; }
        if (setup === "signingIn") return;     // a sign-in is running; its exit re-checks
        cliVersion = o.version || "";
        hasInotify = o.inotify === true;
        systemReducedMotion = o.reducedMotion === true;
        if (o.cli !== true) setup = "noCli";
        else if (o.jq !== true) setup = "noJq";
        else if (o.loggedIn !== true) {
            setup = "signedOut";
            if (_wasSigningIn) {
                _wasSigningIn = false;
                if (loginNote === "") loginNote = "Sign-in did not complete. Try again.";
            }
        } else {
            const first = setup !== "ready";
            setup = "ready";
            loginNote = "";
            if (first && _wasSigningIn) { _wasSigningIn = false; fire("c_success"); }
        }
        startWatcher();
    }
    property bool _wasSigningIn: false
    Process {
        id: checkProc
        stdout: SplitParser { onRead: line => svc._onCheck(line) }
        onExited: code => {
            if (svc._recheckPending) { svc._recheckPending = false; svc.recheck(); return; }
            if (code !== 0 && svc.setup === "checking") svc.setup = "noCli";
        }
    }
    onReadyChanged: { recheck(); startWatcher(); }

    // sign in with the official CLI; the widget shows the link and, if the
    // browser hands out a code instead of finishing by itself, a field for it
    function login() {
        if (!ready || setup === "signingIn") return;
        loginUrl = "";
        loginNote = "";
        _loginCancelled = false;
        _wasSigningIn = true;
        setup = "signingIn";
        loginProc.command = [cmd("companion-login"), loginMethod];
        loginProc.running = true;
    }
    function submitCode(code) {
        const c = String(code).trim();
        if (c.length > 0 && setup === "signingIn") loginProc.write(c + "\n");
    }
    function cancelLogin() {
        _loginCancelled = true;
        _wasSigningIn = false;
        loginProc.running = false;
        setup = "signedOut";
    }
    Process {
        id: loginProc
        stdinEnabled: true
        stdout: SplitParser {
            onRead: line => {
                let o = null;
                try { o = JSON.parse(line); } catch (e) { return; }
                if (o.k === "url") {
                    // only ever offer a link on Claude's own sign-in hosts
                    if (/^https:\/\/(claude\.ai|claude\.com|platform\.claude\.com)\//.test(String(o.url))) svc.loginUrl = o.url;
                    else svc.loginNote = "The sign-in link was not a Claude address, so it was not shown.";
                }
                else if (o.k === "fail") svc.loginNote = o.msg || "Sign-in failed";
            }
        }
        onExited: {
            if (svc._loginCancelled) { svc._loginCancelled = false; return; }
            // the CLI's exit code is not a reliable success signal: ask it
            svc.setup = "checking";
            svc.recheck();
        }
    }

    // ── ClaudeState bridge ─────────────────────────────────────────────────────
    // rawState: what the sources report right now. claudeState: the same plus
    // the two transient outcomes (success / error) derived from busy -> idle.
    property string rawState: "idle"          // idle | thinking | working | waiting
    property string claudeState: "idle"       // idle | thinking | working | waiting | success | error
    property string tool: ""
    property string waitingFor: ""
    property int sessions: 0
    property bool connected: false
    property bool watcherError: false

    // sources: the transcript/session watcher, and the widget's own chat turn.
    property string watchState: "idle"
    property string chatState: "idle"
    function _merge() {
        // the chat turn is authoritative while it runs; otherwise the watcher
        const order = { idle: 0, thinking: 1, working: 2, waiting: 3 };
        svc.rawState = order[chatState] >= order[watchState] ? chatState : watchState;
    }
    onWatchStateChanged: _merge()
    onChatStateChanged: _merge()

    property bool _wasBusy: false
    property bool _errorFlag: false
    onRawStateChanged: {
        const busy = rawState === "thinking" || rawState === "working";
        if (rawState === "idle" && _wasBusy) {
            svc.claudeState = _errorFlag ? "error" : "success";
            svc.fire(_errorFlag ? "c_error" : "c_success");
            _errorFlag = false;
        } else {
            svc.claudeState = rawState;
            if (rawState === "waiting")
                svc.fire(waitingFor.length > 0 ? "c_alert" : "c_waiting");
            else if (rawState === "idle")
                svc.fire("c_idle");
            else
                svc.fire("c_" + rawState);
        }
        _wasBusy = busy || (rawState === "waiting" && _wasBusy);
    }
    onToolChanged: if (rawState === "working") svc.fire("c_working")

    Process {
        id: watcher
        stdout: SplitParser {
            onRead: line => {
                let o = null;
                try { o = JSON.parse(line); } catch (e) { return; }
                if (o.fatal) {
                    svc._disconnected(o.fatal);
                    return;
                }
                svc.connected = true;
                backoff.interval = 5000;
                svc.tool = o.tool || "";
                svc.waitingFor = o.waitingFor || "";
                svc.sessions = o.sessions || 0;
                if (o.error && (o.state !== "idle" || svc._wasBusy)) svc._errorFlag = true;
                svc.watchState = o.state || "idle";
            }
        }
        onExited: code => {
            if (svc._restarting) { svc._restarting = false; return; }
            if (svc.bridgeEnabled) svc._disconnected("watcher exited (" + code + ")");
        }
    }
    property bool _restarting: false
    // start only once pluginDir is known and the helper tools are known to exist
    function startWatcher() {
        if (!ready || !bridgeEnabled || watcher.running) return;
        if (setup === "checking" || setup === "noCli" || setup === "noJq" || !hasInotify) return;
        watcher.command = [cmd("companion-watch")];
        watcher.running = true;
    }
    onBridgeEnabledChanged: {
        if (bridgeEnabled) startWatcher();
        else { watcher.running = false; connected = false; watchState = "idle"; }
    }

    // never crash on a missing/dead source: show ERROR once, then retry slowly.
    Timer {
        id: backoff
        interval: 5000
        onTriggered: {
            if (!svc.bridgeEnabled) return;
            if (watcher.running) svc._restarting = true;
            watcher.running = false;
            svc.startWatcher();
        }
    }
    function _disconnected(why) {
        const was = connected;
        connected = false;
        watchState = "idle";
        if (was || !watcherError) {
            watcherError = true;
            console.warn("claude-companion: bridge down: " + why);
            fire("c_error");
        }
        backoff.interval = Math.min(60000, backoff.interval * 2);
        backoff.restart();
    }
    onConnectedChanged: if (connected) watcherError = false

    // ── explicit state machine ─────────────────────────────────────────────────
    // state -> event -> next state. Claude events (c_*) are routed by `fire`:
    //   c_idle c_thinking c_working c_waiting c_alert c_success c_error
    // Anything not listed is ignored in that state.
    readonly property var table: ({
        IDLE:      { sleep: "SLEEPING", click: "AWAKE",
                     c_thinking: "THINKING", c_working: "WORKING", c_waiting: "LISTENING",
                     c_alert: "ALERT", c_success: "SUCCESS", c_error: "ERROR" },
        SLEEPING:  { click: "AWAKE" },                  // any c_* wakes first (see fire)
        AWAKE:     { timeout: "IDLE" },                 // pending c_* applied on timeout
        THINKING:  { c_working: "WORKING", c_waiting: "LISTENING", c_alert: "ALERT",
                     c_success: "SUCCESS", c_error: "ERROR", c_idle: "IDLE" },
        WORKING:   { c_thinking: "THINKING", c_waiting: "LISTENING", c_alert: "ALERT",
                     c_success: "SUCCESS", c_error: "ERROR", c_idle: "IDLE" },
        LISTENING: { c_thinking: "THINKING", c_working: "WORKING", c_alert: "ALERT",
                     c_success: "SUCCESS", c_error: "ERROR", c_idle: "IDLE" },
        SUCCESS:   { timeout: "IDLE", c_thinking: "THINKING", c_working: "WORKING",
                     c_waiting: "LISTENING", c_alert: "ALERT", c_error: "ERROR" },
        ERROR:     { timeout: "IDLE", c_thinking: "THINKING", c_working: "WORKING",
                     c_waiting: "LISTENING", c_alert: "ALERT", c_success: "SUCCESS" },
        ALERT:     { timeout: "LISTENING", c_thinking: "THINKING", c_working: "WORKING",
                     c_success: "SUCCESS", c_error: "ERROR", c_idle: "IDLE" }
    })
    // how long a transient state lasts before `timeout` fires (ms)
    readonly property var dwell: ({ AWAKE: 1900, SUCCESS: 2600, ERROR: 3200, ALERT: 2400 })

    property string smState: "IDLE"
    property string pending: ""               // c_* event that arrived while asleep/waking

    // what the sprite should show: debug overrides win over the machine; while
    // the first-run setup needs the user, an idle companion keeps asking ("?")
    readonly property var allStates: ["IDLE", "SLEEPING", "AWAKE", "THINKING", "WORKING", "LISTENING", "SUCCESS", "ERROR", "ALERT"]
    property int cycleIndex: 0
    readonly property string animState: debugCycle ? allStates[cycleIndex]
        : (debugState !== "off" ? debugState.toUpperCase()
        : (setupNeeded && smState === "IDLE" ? "LISTENING" : smState))

    function fire(ev) {
        const cur = smState;
        if (ev.indexOf("c_") === 0 && ev !== "c_idle" && (cur === "SLEEPING" || cur === "AWAKE")) {
            pending = ev;
            if (cur === "SLEEPING") _enter("AWAKE");
            return;
        }
        const next = (table[cur] || {})[ev];
        if (next && next !== cur) _enter(next);
    }
    function _enter(s) {
        if (s === "IDLE" && pending !== "" && smState === "AWAKE") {
            // finish waking, then continue with what Claude is doing now
            const p = pending;
            pending = "";
            smState = "IDLE";
            fire(p);
            if (smState === "IDLE") _arm();
            return;
        }
        smState = s;
        if (s !== "AWAKE") pending = "";
        _arm();
    }
    function _arm() {
        const d = dwell[smState];
        if (d !== undefined) { dwellTimer.interval = d; dwellTimer.restart(); }
        else dwellTimer.stop();
        if (smState === "IDLE") { sleepTimer.interval = sleepAfter * 1000; sleepTimer.restart(); }
        else sleepTimer.stop();
    }
    Timer { id: dwellTimer; onTriggered: svc.fire("timeout") }
    Timer { id: sleepTimer; onTriggered: svc.fire("sleep") }
    Component.onCompleted: { _arm(); recheck(); startWatcher(); }
    onSleepAfterChanged: if (smState === "IDLE") _arm()

    // developer cycle: step through every animation, three seconds each
    Timer {
        interval: 3000
        running: svc.debugCycle
        repeat: true
        onTriggered: svc.cycleIndex = (svc.cycleIndex + 1) % svc.allStates.length
    }

    // user poked the character
    function poke() { fire("click"); }

    // ── chat (popup) ───────────────────────────────────────────────────────────
    property ListModel messages: ListModel {}
    property bool chatBusy: false
    property bool chatOpen: false
    property int _streamIdx: -1
    property string chatNote: ""             // live "Reading foo.txt" style activity line

    function send(text) {
        const t = String(text).trim();
        if (!ready || chatBusy || setup !== "ready" || t.length === 0) return;
        messages.append({ role: "user", body: t });
        _streamIdx = -1;
        chatNote = "";
        chatBusy = true;
        chatState = "thinking";
        chatProc.command = [cmd("companion-chat"), "send", stateDirArg(), chatCwd, permissionMode, t];
        chatProc.running = true;
    }
    function cancel() { if (chatBusy) chatProc.running = false; }
    function reset() {
        cancel();
        messages.clear();
        _streamIdx = -1;
        resetProc.command = [cmd("companion-chat"), "reset", stateDirArg()];
        resetProc.running = true;
    }
    function _append(role, text) {
        messages.append({ role: role, body: text });
        _streamIdx = role === "claude" ? messages.count - 1 : -1;
    }
    function _onChatLine(line) {
        let o = null;
        try { o = JSON.parse(line); } catch (e) { return; }
        if (o.k === "text") {
            chatState = "thinking";
            if (_streamIdx < 0) _append("claude", o.t);
            else messages.setProperty(_streamIdx, "body", messages.get(_streamIdx).body + o.t);
        } else if (o.k === "tool") {
            chatState = "working";
            tool = o.name;
            chatNote = o.name + (o.detail ? ": " + o.detail : "");
            _append("tool", chatNote);
        } else if (o.k === "auth") {
            // signed out (or the login expired): back to the sign-in panel
            loginNote = "Claude says you are not signed in. Sign in to continue.";
            _errorFlag = true;
            setup = "signedOut";
            fire("c_alert");
        } else if (o.k === "result") {
            if (!o.ok) { _errorFlag = true; if (_streamIdx < 0) _append("error", o.text || "Claude reported an error"); }
            else if (_streamIdx < 0 && o.text) _append("claude", o.text);
        } else if (o.k === "error") {
            _errorFlag = true;
            _append("error", o.msg);
        }
    }
    Process {
        id: chatProc
        stdout: SplitParser { onRead: line => svc._onChatLine(line) }
        onExited: code => {
            svc.chatBusy = false;
            svc.chatNote = "";
            if (code !== 0 && code !== 15 && code !== 143 && !svc._errorFlag && svc.setup === "ready") svc._errorFlag = true;
            svc.chatState = "idle";
        }
    }
    Process { id: resetProc }
}
