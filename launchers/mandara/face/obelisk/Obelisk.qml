/* Obelisk.qml — The Centered Sentient Modal
 * ============================================
 * The primary interface for SiM. A centered, expanding glass card
 * that houses the Obelisk input, dynamic ROM Host, and telemetry vitals.
 * 
 * ROLE: Supervisor Interface. Derives persistence from internal ROM state.
 * FOLDS: EYE (Search), BLADE (Execution), SAGE (Communication).
 */
import QtQuick
import QtQml
import Quickshell
import QtQuick.Layouts
import QtQuick.Effects
import "../tw" as TW
import "../components"
import "./runes" as Runes

FocusScope {
    id: root
    
    // ── Logic ────────────────────────────────────────────────────────
    SiMController {
        id: _ctrl
        onItemExecuted: function(item) {
            // A breath leaves her open (his word, 2026-10-25):
            // she changes how she drives, in front of him.
            if (item && item.data && item.data.mode) {
                _inputLens.clear();
                return;
            }
            // Keep open for ROMs (Operator's lead)
            if (item && item.category === "actions" && item.data && item.data.isRom) {
                return;
            }
            root.closeRequested();
        }
    }

    // ── Props ────────────────────────────────────────────────────────
    property color  morphColor:    TW.SiMOrchestrator.prismaticColor
    property string query:         ""

    // Her face speaks the user's name, not her own (his word,
    // 2026-10-25): the wordmark seat — and the phantom echoed
    // behind the work — carry whoever she serves.
    readonly property string username: Quickshell.env("USER") || "operator"

    // The lens owns the text; the root mirrors it one-way, so a
    // host assigning root.query (ArShell.dispatchCommand) sets
    // the line without breaking the mirror for the next key.
    Connections {
        target: _inputLens
        function onQueryChanged() {
            if (root.query !== _inputLens.query) root.query = _inputLens.query
        }
    }

    // ── The host contract (May's full Obelisk, grafted) ──────
    // ArShell drives her zones, her reticle and the ScryComm
    // bridge off these members; the extract never grew them and
    // the lanes called into the void. Each is an honest
    // delegation to where Jurai keeps the truth.
    property bool   isThinking:    false
    property string thinkingPhase: "idle"
    property string aiResponse:    ""
    property var    chatMessages:  []
    property var    _resolvedIntent: ({ confidence: 0, cmd: "", entities: {}, context: {} })
    property string lockedTarget:  ""
    // Her seat exists only while she is summoned, and the query
    // — the only thing that moves detectedIp — can only change
    // while she is up. The mirror push reads this; it is true
    // in every moment it can be read.
    property bool   isOpen:        true
    readonly property string activeRom:      _ctrl.activeRomName
    readonly property string activeModality: _inputLens.activeModality
    readonly property real   apmHeat:        TW.SiMOrchestrator.apmHeat
    readonly property string obeliskMode:    root.abyssMode ? "abyss"
        : (_inputLens.lockedTokens.some(function(t) { return (t.cmd || "").startsWith("~") })
           || root.query.startsWith("~")) ? "breathing" : "cognitive"

    // Her mode feeds her morph colour, as it always did — the
    // orchestrator's prismatic chain reads what she declares.
    Binding {
        target: TW.SiMOrchestrator
        property: "obeliskMode"
        value: root.obeliskMode
    }

    Connections {
        target: _ctrl
        function onIsStreamingChanged() {
            root.isThinking = _ctrl.isStreaming || _ctrl.thinkingPhase !== "idle"
        }
        function onThinkingPhaseChanged() {
            root.thinkingPhase = _ctrl.thinkingPhase
            root.isThinking = _ctrl.isStreaming || _ctrl.thinkingPhase !== "idle"
        }
    }

    function openObelisk()  { _inputLens.focusInput() }
    function closeObelisk() { _radial.visible = false }
    function executeAction() { _inputLens.executeRequested() }
    function sendQuery(cmd) {
        // The port's road: a query routed here lands on the
        // lens, the same place a typed line lands — the
        // conversation's room did not cross.
        _inputLens.setText(cmd)
        _inputLens.focusInput()
    }

    // ── April organs, restored (2026-10-20) ─────────────────────
    property bool abyssMode: false
    readonly property string detectedIp: {
        var m = /(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})/.exec(root.query || "")
        return m ? m[1] : ""
    }
    readonly property bool isBidding: {
        var q = (root.query || "").toLowerCase()
        var triggers = ["breach", "infiltrate", "attack", "hack", "pwn"]
        for (var i = 0; i < triggers.length; i++)
            if (q.indexOf(triggers[i]) >= 0) return true
        return false
    }
    // ── The Guardian (April, restored Mandara P3) ──────────
    // A pre-validator at the gate: a bad IPv4 octet or a known
    // flag typo raises her badge and STOPS the execute until
    // the line is fixed or cleared. Her fix is one tap, and it
    // is always labelled AUTHORIZE.
    property string guardianMessage: ""
    property string guardianAutoFix: ""
    function checkGuardian() {
        var q = root.query || ""
        var badIp = q.match(/\b(?:25[6-9]|2[6-9][0-9]|[3-9][0-9]{2})\.\d{1,3}\.\d{1,3}\.\d{1,3}\b/)
        if (badIp) {
            root.guardianMessage = "Invalid IPv4 Octet detected (>255)."
            root.guardianAutoFix = q.replace(badIp[0], "127.0.0.1")
        } else if (q.includes("--stealt") && !q.includes("--stealth")) {
            root.guardianMessage = "Unknown flag. Did you mean --stealth?"
            root.guardianAutoFix = q.replace("--stealt", "--stealth")
        } else {
            root.guardianMessage = ""
            root.guardianAutoFix = ""
        }
    }
    property bool hasCollision: false
    function checkCollision() {
        var q = (root.query || "").toLowerCase()
        root.hasCollision = (q.includes("-windows") && q.includes("-linux"))
                         || (q.includes("-stealth") && q.includes("-aggressive"))
                         || (q.includes("-pass") && q.includes("-fuzz"))
    }

    // ── The gate, in the port ──────────────────────────────
    // In Jurai shell the One Law stood here: hunt lines were
    // carried to the core and judged against the active
    // mission, and the house verbs (/mission, /sign, /song)
    // opened the ledger's doors. The core did not cross into
    // the launcher, and neither did its law or its ledger —
    // the Guardian above keeps her local watch (spelling and
    // collisions), and every line takes the resolver's road.
    // What remains of the house's voice is the notice: the
    // stamp still speaks when something must be said.

    // The notice: what the stamp says when the house has
    // spoken (2026-10-23). A verb's reply rides the stamp
    // because the stamp is where his eyes already check
    // her state — the result strip below the lens and the
    // notification model both swallowed replies whole
    // (the strip hangs outside the plate's extent; no
    // seated surface renders the model). Twelve seconds,
    // or until he types again.
    property string notice: ""
    Timer {
        id: _noticeTimer
        interval: 12000
        onTriggered: root.notice = ""
    }
    function _speak(text, stampText) {
        _inputLens.inlineResult = text
        root.notice = (stampText !== undefined && stampText !== "") ? stampText : text
        _noticeTimer.restart()
    }

    // The dispatch a line takes — the controller's road
    // (apps, actions, files), the very road an unjudged line
    // always took. The ROM branch and the conversation to
    // Insei's room lived on the core; they did not cross.
    function _dispatch(finalQuery) {
        _ctrl.setSearchQuery(finalQuery)
        _ctrl.executeSelected()
        _inputLens.clear()
        _inputLens.lockedTokens = []
    }

    // What she understood, in her own grammar (April's rules) —
    // the lens displays it on the cleared line, a memory.
    // April's translations named the hunt roads; those roads
    // did not cross, so the line rests empty in the port.
    property string translatedIntent: ""
    function updateTranslatedIntent() {
        root.translatedIntent = ""
    }

    onQueryChanged: {
        if (root.query !== "") root.notice = ""
        root.checkGuardian()
        root.checkCollision()
        root.updateTranslatedIntent()
    }

    property alias  activeRomPath: _ctrl.activeRomPath
    property var    controller:    _ctrl
    property bool   showCommandRef: false
    
    signal closeRequested()
    signal ipRadialRequested(string ip)

    // The AR-shell contract (restored 2026-10-20): the shigurui
    // generation's hosts seat the Obelisk with a cursor feed and
    // a command history, and listen for these two signals — all
    // dropped in the SiM extract. Declared so any root can host
    // her; Mandara's wrapper reads what it needs directly.
    property real cursorX: 0
    property real cursorY: 0
    property var  commandHistory: []
    signal executeCommand(string cmd)
    signal conduitToggleRequested(string panel)
    
    // ── Geometry ──────────────────────────────────────────────────────
    width:  540
    height: parent ? parent.height : 800
    anchors.centerIn: parent
    
    // ── The Plate (Mandara P1, 2026-10-22) ─────────────────────
    // She floated on a transparent nothing; now she stands on a
    // plate in the house dialect: smoked glass in her own TW
    // palette, a prism rim in her morph colour, corner ticks,
    // her name ghosted behind the work, her emblem at the
    // head — and a stamp footer that speaks her state and teaches the keys. The
    // plate hugs the monocle's living extent and settles as
    // she thinks.
    readonly property real aboveExtent: Math.max(
        _resultsList.visible ? _resultsList.height + 16 : 0,
        _cmdRef.visible ? 316 : 0)
    readonly property real belowExtent: {
        var g = _guardianBay.visible ? _guardianBay.height + 10 : 0
        var t = _tracksBay.visible ? _tracksBay.height + 8 : 0
        var p = _portal.visible ? _portal.height + 16 : 0
        return g + t + p
    }

    Item {
        id: _plate
        z: -1
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width + 36
        y: _inputLens.y - root.aboveExtent - 70
        height: 70 + root.aboveExtent + _inputLens.height
                + Math.max(root.belowExtent, 10) + 40
        Behavior on y { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        Rectangle {
            anchors.fill: parent
            radius: 14
            color: TW.TransparentWorld.glassBaseDense
            border.color: Qt.alpha(root.morphColor, 0.35)
            border.width: 1
        }

        // Phantom — the user's name behind the work, echo first.
        Text {
            x: parent.width - width - 14 + 3
            y: 30 + 2
            text: root.username.toUpperCase()
            font.family: Typography.technical
            font.weight: 700
            font.pixelSize: 54
            font.letterSpacing: 10
            color: Qt.alpha(root.morphColor, 0.045)
        }
        Text {
            x: parent.width - width - 14
            y: 30
            text: root.username.toUpperCase()
            font.family: Typography.technical
            font.weight: 700
            font.pixelSize: 54
            font.letterSpacing: 10
            color: Qt.alpha(root.morphColor, 0.06)
        }

        // Corner ticks — the family's registration marks.
        // Each bracket faces the plate's heart: its bars hug
        // the corner's own two edges (all four once opened
        // the same way — his eye caught it, 2026-10-25).
        Repeater {
            model: 4
            delegate: Item {
                readonly property bool leftSide: index % 2 === 0
                readonly property bool topSide: index < 2
                width: 10; height: 10
                x: leftSide ? 6 : _plate.width - 16
                y: topSide ? 6 : _plate.height - 16
                Rectangle {
                    width: 10; height: 2
                    x: 0
                    y: parent.topSide ? 0 : 8
                    color: Qt.alpha(root.morphColor, 0.55)
                }
                Rectangle {
                    width: 2; height: 10
                    x: parent.leftSide ? 0 : 8
                    y: 0
                    color: Qt.alpha(root.morphColor, 0.55)
                }
            }
        }

        // The head — her emblem, the user's name plate.
        Row {
            x: 16
            y: 12
            spacing: 10

            // Her mark — the Jurai emblem at high resolution
            // (1024 master), mipmapped so the downscale to
            // her seat stays clean, seated where the orb
            // turned (his word, 2026-10-25: brand her with
            // the logo, not the water — and keep it readable).
            Image {
                width: 36
                height: 36
                source: "../components/emblem.png"
                fillMode: Image.PreserveAspectFit
                smooth: true
                mipmap: true
            }
            Column {
                spacing: 1
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: root.username.toUpperCase()
                    font.family: Typography.technical
                    font.weight: 700
                    font.pixelSize: 14
                    font.letterSpacing: 4
                    color: Qt.rgba(0.93, 0.95, 1.0, 0.95)
                }
            }
        }

        // The stamp — her state, spoken; the keys, taught.
        Row {
            x: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            spacing: 8
            Rectangle {
                width: 22
                height: 3
                anchors.verticalCenter: parent.verticalCenter
                color: _ctrl.isSearching
                       ? root.morphColor : Qt.rgba(1, 1, 1, 0.3)
            }
            Text {
                text: "MANDARA // " + (root.notice !== ""
                        ? root.notice
                        : TW.SiMOrchestrator.driveMode.toUpperCase() + " · " + (root.abyssMode
                        ? "VOID — SHELL PASSTHROUGH"
                        : root.hasCollision
                        ? "COLLISION — THE LINE FIGHTS ITSELF"
                        : root.query !== "" ? "SEEKING" : "READY"))
                font.family: Typography.technical
                font.pixelSize: 9
                font.letterSpacing: 2
                color: Qt.rgba(1, 1, 1, 0.55)
            }
        }
        Text {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 12
            text: (_inputLens.query !== "" || _inputLens.lockedTokens.length > 0)
                ? "ESC PEELS · CTRL+U CLEARS · ENTER RUNS · TAB LOCKS A RUNE"
                : "↑↓ CHOOSE · ENTER RUNS · CTRL+1-9 CASTS · ESC RETIRES"
            font.family: TW.TransparentWorld.fontFamily
            font.pixelSize: 9
            color: Qt.rgba(1, 1, 1, 0.35)
        }
    }

    // ── Content Layout — Fixed Center Monocle Layout ─────────────────

    // 2. Results List (Vertical — Above Lens)
    SiMResultsList {
        id: _resultsList
        width: parent.width
        height: implicitHeight
        anchors.bottom: _inputLens.top
        anchors.bottomMargin: 16
        controller: _ctrl
        morphColor: root.morphColor
        visible: !root.showCommandRef && controller && controller.searchQuery.length > 0 && controller.flatModel.length > 0
    }

    // 2.5 Command Reference (Matrix Overlay — Above Lens)
    Runes.CommandReference {
        id: _cmdRef
        width: parent.width
        height: 300
        anchors.bottom: _inputLens.top
        anchors.bottomMargin: 16
        visible: root.showCommandRef
        morphColor: root.morphColor
        onCommandSelected: function(cmd) {
            _inputLens.query = cmd
            root.showCommandRef = false
        }
    }

    // 3. The Input Lens (Perfect Stationary Center Monocle)
    Runes.InputLens {
        id: _inputLens
        width: parent.width
        anchors.verticalCenter: parent.verticalCenter
        focus: true
        
        morphColor: root.morphColor
        abyssMode:  root.abyssMode
        translatedIntent: root.translatedIntent
        apmHeat:    TW.SiMOrchestrator.apmHeat
        ghostSource: _ctrl.ghostCompletion
        radialAvailable: root.detectedIp !== ""
        
        onCloseRequested: root.closeRequested()

        // ── Her keyboard, wired (2026-10-25) ─────────────────
        // The lens's arrow and number signals hung unconnected
        // in the port — selection moved only under the mouse.
        // Now: arrows walk, Ctrl+J/K/N/P walk with them, Page
        // and Ctrl+arrows jump sections, Ctrl+digit casts the
        // nth entry outright (the portal's badges promised it),
        // and Escape peels one layer at a time — radial, then
        // chips, then the line — before it retires her.
        onArrowDown: _ctrl.selectNext()
        onArrowUp: _ctrl.selectPrevious()
        onSectionNext: _ctrl.selectSection(1)
        onSectionPrev: _ctrl.selectSection(-1)
        onNumberPressed: function(num) {
            if (_portal.visible && num >= 1 && num <= _portal.items.length) {
                _portal.itemSelected(_portal.items[num - 1])
            } else {
                _ctrl.castOrdinal(num)
            }
        }
        onEscPressed: {
            if (_radial.visible) {
                _radial.visible = false
                _inputLens.focusInput()
            } else if (_inputLens.lockedTokens.length > 0) {
                _inputLens.lockedTokens = []
            } else if (_inputLens.query !== "") {
                _inputLens.clear()
            } else {
                root.closeRequested()
            }
        }
        
        onTextEdited: function(text) {
            TW.SiMOrchestrator.recordKeystroke()
            _ctrl.setSearchQuery(text)
        }
        
        onExecuteRequested: {
            if (root.guardianMessage !== "") return
            if (root.hasCollision) return

            // The first locked segment may be a DOOR, not a word
            // in a line (his word, 2026-10-25): the breaths, open,
            // find and ask act on the spot instead of assembling.
            var _toks = _inputLens.lockedTokens
            if (_toks.length > 0 && _toks[0].action) {
                var _act = _toks[0].action
                var _rest = root.query
                if (_act === "mode") {
                    TW.SiMOrchestrator.setDriveMode(_toks[0].id)
                    _inputLens.lockedTokens = []
                    _inputLens.clear()
                    return
                }
                if (_act === "open") {
                    _inputLens.lockedTokens = []
                    _inputLens.setText(_rest)
                    return
                }
                if (_act === "files") {
                    _inputLens.lockedTokens = []
                    _inputLens.clear()
                    _ctrl.setSearchQuery("files " + _rest)
                    return
                }
                if (_act === "rashin") {
                    _inputLens.lockedTokens = []
                    _inputLens.clear()
                    TW.SiMOrchestrator.requestRashin(_rest)
                    return
                }
            }

            // Rune Assembly first: locked tokens and the raw
            // query as one line — every road below reads it.
            var finalQuery = root.query
            if (_inputLens.lockedTokens.length > 0) {
                // Assembly: a segment template carrying "{arg}"
                // takes the line's remainder into itself; other
                // segments lead and the remainder follows.
                var parts = []
                var argUsed = false
                for (var i = 0; i < _inputLens.lockedTokens.length; i++) {
                    var pc = _inputLens.lockedTokens[i].cmd || _inputLens.lockedTokens[i].label
                    if (pc.indexOf("{arg}") >= 0) {
                        pc = pc.split("{arg}").join(finalQuery)
                        argUsed = true
                    }
                    parts.push(pc)
                }
                if (!argUsed && finalQuery.trim() !== "") {
                    parts.push(finalQuery)
                }
                finalQuery = parts.join(" ")
            }

            // Abyss rite (April, restored): the word "abyss"
            // toggles the mode; in the mode, everything runs
            // as shell and she stays open.
            if (_inputLens.lockedTokens.length === 0 && root.query.trim().toLowerCase() === "abyss") {
                root.abyssMode = !root.abyssMode
                _inputLens.clear()
                return
            }

            if (root.abyssMode) {
                TW.SiMOrchestrator.runNativeCommand(finalQuery)
                        _inputLens.clear()
                _inputLens.lockedTokens = []
                return
            }

            root._dispatch(finalQuery)
        }
        
        onTabPressed: {
            if (root.detectedIp !== "") {
                _radial.targetIp = root.detectedIp
                _radial.visible = true
                root.ipRadialRequested(root.detectedIp)
            }
        }
    }
    
    // 3.5 The Guardian's bay — she stands between the lens and
    // the stream when the line is wounded.
    Item {
        id: _guardianBay
        anchors.top: _inputLens.bottom
        anchors.topMargin: 8
        width: parent.width
        height: visible ? 46 : 0
        visible: root.guardianMessage !== "" || root.hasCollision

        OmnibarGuardianBadge {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            message: root.guardianMessage !== "" ? root.guardianMessage
                     : "COLLISION — contradictory flags in one line."
            autoFix: root.guardianAutoFix
            onApplyFix: function(fixed) {
                if (fixed === "") return
                _inputLens.setText(fixed)
                _inputLens.focusInput()
            }
        }
    }

    // 3.75 Branching Tracks (April, restored Mandara P4) — a
    // line carrying [a|b] forks into her resolved timelines.
    Item {
        id: _tracksBay
        anchors.top: _guardianBay.visible ? _guardianBay.bottom : _inputLens.bottom
        anchors.topMargin: 8
        width: parent.width
        height: visible ? _tracks.implicitHeight : 0
        visible: _tracks.visible

        OmnibarBranchingTracks {
            id: _tracks
            width: parent.width
            query: root.query
            onTrackSelected: function(resolved) {
                _inputLens.setText(resolved)
                _inputLens.focusInput()
            }
        }
    }

    // 4. Suggestions (Horizontal Stream — Below Lens)
    LucidPortal {
        id: _portal
        width: parent.width
        anchors.top: _tracksBay.visible ? _tracksBay.bottom : _guardianBay.visible ? _guardianBay.bottom : _inputLens.bottom
        anchors.topMargin: 16
        visible: (_ctrl.searchQuery !== "" || _inputLens.lockedTokens.length > 0) && _portal.items.length > 0
        items: _ctrl.suggestions(root.query, _inputLens.lockedTokens)
        morphColor: root.morphColor

        onItemSelected: function(item) {
            if (item.kind === "app") {
                _ctrl.launchSuggestion(item)
                _inputLens.clear()
                _inputLens.lockedTokens = []
            } else if (item.isPreset) {
                var fullCmd = item.preview
                var words = fullCmd.split(/\s+/)
                words.shift() // remove the tool name since it's already locked as a chip
                var remainder = words.join(" ")
                _inputLens.setText(remainder)
                _inputLens.focusInput()
            } else {
                var rune = Runes.RuneRegistry.resolve(item.id) || item
                _inputLens.lockToken(rune)
            }
        }
    }



    // 8. Holo Emitter (April — a target in the query raises the ring)
    OmnibarHoloEmitter {
        anchors.bottom: _inputLens.top
        anchors.bottomMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        detectedIp: root.detectedIp
    }


    // 9. The Diamond (April, restored Mandara P3) — Tab with a
    // target in the query blooms the wheel around it.
    OmnibarRadialMenu {
        id: _radial
        anchors.fill: parent
        z: 40
        visible: false
        onActionSelected: function(cmd) {
            _inputLens.setText(cmd)
            _inputLens.focusInput()
        }
        onClosed: {
            _radial.visible = false
            _inputLens.focusInput()
        }
    }

    // ── Global Key Handling ──────────────────────────────────────────
    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            if (_radial.visible) {
                _radial.visible = false
                _inputLens.focusInput()
            } else if (_ctrl.activeRomPath !== "") {
                _ctrl.closeRom()
            } else {
                root.closeRequested()
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            _ctrl.selectNext()
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            _ctrl.selectPrevious()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            _ctrl.executeSelected()
            event.accepted = true
        }
    }
}
