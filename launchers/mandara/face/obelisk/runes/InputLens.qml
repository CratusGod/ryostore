/* InputLens.qml — V5 Cognitive Zenith
 * Thermal input bar with:
 *   · Morph theme border (cerulean/blood violet/strike-rose/forge-indigo)
 *   · Rune system — Tab-cast NLU tokens as SDF crystal chips
 *   · Translated intent ghost display
 *   · Ghost text suffix
 *   · Ember + Spark + Ripple VFX
 *   · Scanline/noise shader overlay
 *   · APM heat reactive sparks
 */
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "." as Runes
import "../../tw" as TW

Rectangle {
    id: root

    // ── Props ────────────────────────────────────────────────────────
    property string query:            ""
    property string ghostText:        ""
    // The ghost's second source — the Obelisk feeds the resolver's
    // own completion here; a rune's completion outranks it.
    property string ghostSource:      ""
    property string _registryGhost:   ""
    onGhostSourceChanged: {
        if (root._registryGhost === "") root.ghostText = root.ghostSource
    }
    property string prediction:       ""   // full-word underlay ghost (prefix match from known terms)
    property string translatedIntent: ""
    property string currentContext:   "global"
    property string liveContext:      ""   // overrides badge when non-empty (tool execution state)
    property bool   isMacro:          false
    property bool   isError:          false
    property bool   isAtelierActive:  false
    property bool   abyssMode: false
    property bool   isListening:      false
    property bool   isThinking:       false
    property bool   hasCollision:     false
    property bool   showGuardian:     false
    property int    apmHeat:          0
    property color  morphColor:       "#00B4D8"
    property real   morphGlow:        0.18
    property string portalHint:       ""   // "/" or "@" for single-character portal hints
    property bool radialAvailable: false
    property string obeliskMode:      "cognitive"
    property string modeBadge:        "[COGNITIVE]"
    property string thinkingPhase:    "recall" // "recall"|"reason"|"respond"
    property string activeModality:   "cognitive"
    property string shadowStatus:     "unknown"
    property string breathingStyle:   "water"
    property string inlineResult:     ""   // transient result line shown below input
    property real   intentConfidence: 0.0  // from _resolvedIntent.confidence
    property string intentDescription: "" // from _resolvedIntent.description
    property bool   intentPending:    false // NLU classify in flight

    // ── Bioluminescent breathing pulse animation ──────────────────
    property real _pulseFactor: 0.0
    SequentialAnimation on _pulseFactor {
        loops: Animation.Infinite
        running: true
        NumberAnimation { to: 1.0; duration: 2400; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.0; duration: 2400; easing.type: Easing.InOutSine }
    }

    // ── Pending rune — NLU matched a rune, Tab should cast it not append text ─
    property bool   hasPendingRune:   false
    property var    pendingRune:      null  // { id, label, icon, color, cmd, terminal }

    // ── Locked runes — Tab-cast NLU segments ─────────────────────────
    // Each: { id, label, icon, color, cmd, terminal }
    property var lockedTokens: []

    // ── Locked breathing style — drives sigil + color anticipation ────
    // The first locked breathing rune (cmd starts with "~") takes over
    // the leading sigil and morphs the system color immediately.
    // lockedStyleName is passed from Obelisk._lockedBreathingStyleName —
    // it persists after the chip shatters.
    property string lockedStyleName: ""

    readonly property var _lockedBreathingRune: {
        // First check the persistent locked style name (survives chip shatter)
        if (lockedStyleName !== "") {
            // Reconstruct a minimal rune object from the style name
            var styleColors = {
                "sun": "#f59e0b", "moon": "#818cf8", "celestial": "#ffffff", "star": "#ffffff"
            }
            var styleIcons = {
                "sun": "☀", "moon": "☽", "celestial": "✧", "star": "✧"
            }
            return {
                id: lockedStyleName, label: lockedStyleName,
                icon: styleIcons[lockedStyleName] || "◈",
                color: styleColors[lockedStyleName] || "#00B4D8",
                cmd: "~" + lockedStyleName, terminal: true
            }
        }
        // Fallback: scan live chip array (during the brief window before shatter)
        for (var i = 0; i < lockedTokens.length; i++) {
            if (lockedTokens[i].cmd && lockedTokens[i].cmd.startsWith("~"))
                return lockedTokens[i]
        }
        return null
    }
    readonly property string _lockedStyleName: _lockedBreathingRune
        ? (_lockedBreathingRune.label || _lockedBreathingRune.id || "").toUpperCase()
        : ""

    signal tokenLocked(var token)
    signal tokenShattered(var token)
    signal styleCleared()   // emitted on Backspace when input empty + no chips — clears locked style

    function lockTopSuggestion() {
        // Called by Tab when no ghost text — locks the top portal suggestion
        // as a visual token chip and clears the input for the next segment
        // This signal is handled by Obelisk.qml
        root.tabPressed()
    }

    function lockToken(token) {
        if (!token) return
        var arr = lockedTokens.slice()
        arr.push(token)
        lockedTokens = arr
        query = ""
        commandInput.text = ""
        hasPendingRune = false
        pendingRune = null
        root.tokenLocked(token)
    }

    function lockPendingRune() {
        if (!hasPendingRune || !pendingRune) return
        lockToken(pendingRune)
    }

    function shatterLastToken() {
        if (lockedTokens.length === 0) return
        // Trigger shatter animation on the last RuneChip, then remove it.
        // The chip's shatterComplete signal fires after 320ms — we remove
        // the item from the model at that point via a short timer.
        var lastIdx = _runeRepeater.count - 1
        if (lastIdx >= 0) {
            var chip = _runeRepeater.itemAt(lastIdx)
            if (chip && typeof chip.shatter === "function") {
                chip.shatter()
                // Remove from model after shatter animation completes
                var arr = lockedTokens.slice()
                var last = arr.pop()
                Qt.callLater(function() {
                    lockedTokens = arr
                    root.tokenShattered(last)
                })
                return
            }
        }
        // Fallback: immediate removal if chip ref unavailable
        var arr2 = lockedTokens.slice()
        var last2 = arr2.pop()
        lockedTokens = arr2
        root.tokenShattered(last2)
        ghostLayer.startShatter()
    }

    // ── Breathing style ember color ───────────────────────────────────
    readonly property color emberColor: {
        var s = breathingStyle
        if (s === "sun")       return "#f59e0b"
        if (s === "moon")      return "#818cf8"
        if (s === "celestial") return "#ffffff"
        if (s === "star")      return "#ffffff"
        return morphColor   // cognitive / default — follows morph
    }
    property color thermalColor: {
        var h = apmHeat
        var apmFactor = apmHeat / 100.0

        if (breathingStyle === "flame") {
            // Solar Orange (#fb923c) → White Hot (#ffffff) based on APM
            var fr = 251 + apmFactor * (255 - 251)
            var fg = 146 + apmFactor * (255 - 146)
            var fb = 60  + apmFactor * (255 - 60)
            return Qt.rgba(fr / 255, fg / 255, fb / 255, 1.0)
        }

        if (isMacro) {
            // amber (#f59e0b) → indigo (#818cf8)
            var tr = Math.round(245 - h * (245 - 129))
            var tg = Math.round(158 - h * (158 - 140))
            var tb = Math.round(11  + h * (248 - 11))
            return Qt.rgba(tr / 255, tg / 255, tb / 255, 1.0)
        } else {
            // cerulean (#22d3ee) → rose (#f43f5e)
            var tr2 = Math.round(34  + h * (244 - 34))
            var tg2 = Math.round(211 - h * (211 - 63))
            var tb2 = Math.round(238 - h * (238 - 94))
            return Qt.rgba(tr2 / 255, tg2 / 255, tb2 / 255, 1.0)
        }
    }

    // Ripples still driven from parent
    property var ripples: []

    // ── Inline lex — the line, read as she reads it ──────────
    // (The crystallized-syntax layer was removed when the Rune
    // system replaced it, and revived 2026-10-25 on her
    // author's word — the chips lock above, the lex tints
    // inline; the two grammars stand together now.)
    function _lexColor(w, isFirst) {
        if (/^-?\d/.test(w)) return ""
        var probe = w
        if (isFirst && probe.length > 1 && "/~#?@".indexOf(probe.charAt(0)) >= 0)
            probe = probe.substring(1)
        var hit = null
        try { hit = Runes.RuneRegistry.match(probe) } catch (e) { hit = null }
        if (hit && hit.color) return String(hit.color)
        if (w.startsWith("--") && w.length > 3) return "#FFB300"
        if (w.startsWith("\"") || w.startsWith("'")) return "#C8B8FF"
        if (w.indexOf("/") >= 0) return "#00B4D8"
        return ""
    }

    function _lexHtml(text) {
        if (!text) return ""
        var parts = text.split(/( )/)
        var out = ""
        var firstWord = true
        for (var i = 0; i < parts.length; i++) {
            var w = parts[i]
            if (w === " ") { out += "&nbsp;"; continue }
            if (w === "") continue
            var esc = w.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
            var c = root._lexColor(w, firstWord)
            out += "<font color=\"" + (c === "" ? "#00000000" : c) + "\">" + esc + "</font>"
            firstWord = false
        }
        return out
    }
    // The NLU in Obelisk.qml classifies intent and emits rune objects;
    // Tab locks them as RuneChip instances. Plain text stays plain.

    // ── Signals ──────────────────────────────────────────────────────
    signal textEdited(string text)
    signal executeRequested()
    signal stealthToggled()
    signal closeRequested()
    signal escPressed()
    signal tabPressed()
    signal arrowUp()
    signal arrowDown()
    signal sectionNext()
    signal sectionPrev()
    signal numberPressed(int num)  // For ⌘1-⌘9 hotkey selection
    signal ghostAccepted()
    signal ctrlKey(string key)   // stood down in the launcher (2026-10-25) — kept for the face's compat

    // ── Geometry ─────────────────────────────────────────────────────
    height: activeModality === "reflex" ? 38 : (activeModality === "architect" ? 56 : 48)
    radius: height / 2
    color: {
        if (activeModality === "reflex") return Qt.rgba(0.039, 0, 0, 0.92)
        var baseAlpha = commandInput.activeFocus ? 0.86 : 0.74
        var r = 0.04 + root._pulseFactor * 0.015
        var g = 0.06 + root._pulseFactor * 0.015
        var b = 0.11 + root._pulseFactor * 0.02
        return Qt.rgba(r, g, b, baseAlpha)
    }

    // Flat drop shadow
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0, 0, 0, 0.35)
        shadowBlur: 0.3
        shadowVerticalOffset: 4
        shadowHorizontalOffset: 0
    }

    Behavior on height { NumberAnimation { duration: 250; easing.type: Easing.OutBack } }
    Behavior on radius { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    Behavior on color  { ColorAnimation  { duration: 350; easing.type: Easing.InOutQuad } }

    // ── Execute border pulse ──────────────────────────────────────────
    property real _executePulse: 0.0
    NumberAnimation on _executePulse {
        id: executePulseDecay
        to: 0.0; duration: 500; easing.type: Easing.OutCubic
        running: false
    }

    border.color: {
        if (isError) return "#f43f5e"
        if (shadowStatus === "fail")    return "#f43f5e"
        if (shadowStatus === "caution") return "#fbbf24"
        if (shadowStatus === "pass")    return "#10b981"
        if (activeModality === "reflex") return "#ff0033"
        var alpha = (commandInput.activeFocus ? 0.38 : 0.18) + root._pulseFactor * 0.12
        return Qt.rgba(morphColor.r, morphColor.g, morphColor.b, alpha)
    }
    border.width: 1
    Behavior on border.color { ColorAnimation { duration: 80 } }
    Behavior on morphColor   { ColorAnimation { duration: 300 } }

    // Top shimmer
    Rectangle {
        anchors.top:   parent.top
        anchors.left:  parent.left
        anchors.right: parent.right
        anchors.margins: 1
        height: 1; radius: parent.radius
        color: Qt.rgba(1, 1, 1, 0.06)
    }

    // ── RIPPLE VFX ───────────────────────────────────────────────────
    Repeater {
        model: root.ripples.length
        delegate: Rectangle {
            anchors.centerIn: parent
            width: root.width; height: root.height
            radius: root.radius
            color: "transparent"
            border.color: root.morphColor
            border.width: 2
            opacity: 0
            SequentialAnimation on scale   { running: true; NumberAnimation { from: 1.0; to: 4.0; duration: 800; easing.type: Easing.OutCubic } }
            SequentialAnimation on opacity { running: true; NumberAnimation { from: 0.5; to: 0.0; duration: 800; easing.type: Easing.OutCubic } }
        }
    }

    // ── The cursor's seat, mapped fresh at spawn time ────────
    // Input triggers the fall, so the fall begins directly
    // beneath the caret as it stands this keystroke: the caret
    // rectangle mapped from the field into the canvas's own
    // coordinates, its bottom edge the spawn line. (His word,
    // 2026-10-25 — a cached, offset guess stood here before.)
    function _cursorPointNow() {
        var r = commandInput.cursorRectangle
        return commandInput.mapToItem(emberCanvas, r.x + r.width / 2, r.y + r.height)
    }

    // ── UNIFIED ANIMATION LOOP — 16ms (~60fps) ───────────────────────
    property real _animTime: 0.0
    property real _lastSparkTime: 0.0
    property int _activeParticleCount: 0

    Timer {
        id: animLoop
        interval: 16
        repeat: true
        running: root._activeParticleCount > 0 || root.query !== "" || root.isListening
        onTriggered: {
            root._animTime += 0.016
            // Update particles every frame, honestly timed —
            // a doubled dt once flung them to the lens's floor
            // in a blink, reading as spawns at the bottom edge
            // instead of a fall from the caret.
            if (root._activeParticleCount > 0) {
                emberCanvas._updateParticles(0.016)
                emberCanvas.requestPaint()
            }
            // Sync shader time
            ghostLayer._shaderTime = root._animTime
            // Update GhostText state (consolidated from separate timer)
            ghostLayer.updateState(0.016)
        }
    }

    // ── EMBER PARTICLES — 34-particle pool, object reuse ─────────────
    // The canvas outgrows the lens downward: the fall begins
    // at the caret's foot and continues past the lens's edge
    // over the plate, or it reads as a blink at the line.
    Canvas {
        id: emberCanvas
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: parent.height + 96
        renderStrategy: Canvas.Cooperative
        renderTarget:   Canvas.FramebufferObject

        // 34-particle pre-allocated pool
        property var _pool: []
        property int _poolIndex: 0
        property int _activeCount: 0

        Component.onCompleted: {
            // Initialize pool with 34 particles
            for (var i = 0; i < 34; i++) {
                _pool.push({
                    active: false,
                    x: 0, y: 0,
                    vx: 0, vy: 0,
                    wobble: 0,
                    age: 0,
                    life: 0,
                    size: 0,
                    color: "#00B4D8",
                    isSpark: false
                })
            }
        }

        function _acquireParticle() {
            // Find inactive particle (round-robin from poolIndex)
            for (var i = 0; i < 34; i++) {
                var idx = (_poolIndex + i) % 34
                if (!_pool[idx].active) {
                    _poolIndex = (idx + 1) % 34
                    _pool[idx].active = true
                    _activeCount++
                    root._activeParticleCount = _activeCount
                    return _pool[idx]
                }
            }
            return null  // pool exhausted
        }

        function spawnEmber(cursorX, cursorY, color) {
            var p = _acquireParticle()
            if (!p) return
            p.wobble = (Math.random() - 0.5) * 0.8
            p.x = cursorX + (Math.random() - 0.5) * 3
            p.y = cursorY + 1
            p.vx = (Math.random() - 0.5) * 22
            p.vy = 3 + Math.random() * 5
            p.age = 0
            p.life = 1.0
            p.size = 1.5 + Math.random() * 2.0
            p.color = color || "#00B4D8"
            p.isSpark = false
        }

        function spawnSpark(cursorX, cursorY) {
            var p = _acquireParticle()
            if (!p) return
            p.x = cursorX + (Math.random() - 0.5) * 8
            p.y = cursorY + 1
            p.vx = (Math.random() - 0.5) * 36
            p.vy = 14 + Math.random() * 16
            p.age = 0
            p.life = 1.0
            p.color = "#facc15"
            p.isSpark = true
            p.size = 1.5
        }

        function _updateParticles(dt) {
            for (var i = 0; i < 34; i++) {
                var p = _pool[i]
                if (!p.active) continue

                p.age += dt
                p.x += (p.vx + Math.sin(p.age * 4.2 + p.wobble * 6.28) * 6) * dt
                p.y += p.vy * dt
                p.vy += (p.isSpark ? 2.2 : 0.55) * dt * 60
                p.vx *= 0.97
                p.life -= dt * (p.isSpark ? 1.4 : 0.65)

                if (p.life <= 0) {
                    p.active = false
                    _activeCount--
                    root._activeParticleCount = _activeCount
                }
            }
        }

        onPaint: {
            if (_activeCount === 0) return  // Dirty tracking - skip if no particles
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            for (var i = 0; i < 34; i++) {
                var p = _pool[i]
                if (!p.active) continue

                var r = p.size || 2.0
                var c = Qt.color(p.color || "#00B4D8")
                var a = p.life || 0.0

                // Validate coordinates before drawing
                if (!isFinite(p.x) || !isFinite(p.y) || !isFinite(r)) continue

                // Outer soft glow
                var grd = ctx.createRadialGradient(p.x, p.y, 0, p.x, p.y, r * 4)
                grd.addColorStop(0,   Qt.rgba(c.r, c.g, c.b, a * 0.35))
                grd.addColorStop(1,   Qt.rgba(c.r, c.g, c.b, 0))
                ctx.beginPath()
                ctx.arc(p.x, p.y, r * 4, 0, Math.PI * 2)
                ctx.fillStyle = grd
                ctx.fill()

                // Core ember dot
                ctx.beginPath()
                ctx.arc(p.x, p.y, r, 0, Math.PI * 2)
                ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, a * 0.95)
                ctx.fill()

                // Hot white center on fresh embers
                if (a > 0.6) {
                    ctx.beginPath()
                    ctx.arc(p.x, p.y, r * 0.4, 0, Math.PI * 2)
                    ctx.fillStyle = Qt.rgba(1, 1, 1, (a - 0.6) * 1.5)
                    ctx.fill()
                }
            }
        }
    }

    // Spawn points are the caret's own seat, mapped fresh —
    // the embers and sparks fall from directly beneath it.
    function spawnEmber() {
        var pt = root._cursorPointNow()
        emberCanvas.spawnEmber(pt.x, pt.y, root.emberColor.toString())
    }
    function spawnSpark() {
        var pt = root._cursorPointNow()
        emberCanvas.spawnSpark(pt.x, pt.y)
    }

    // ── MAIN ROW ─────────────────────────────────────────────────────
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin:  activeModality === "reflex" ? 12 : 24
        anchors.rightMargin: activeModality === "reflex" ? 12 : 24
        spacing: activeModality === "reflex" ? 8 : 16

        // ── Leading sigil — SiMSoulSigil (idle) or style icon (locked) ──
        Item {
            width: 20; height: 20
            Layout.alignment: Qt.AlignVCenter

            // SiMSoulSigil — default state, scales to fit the lens height
            Runes.SiMSoulSigil {
                anchors.centerIn: parent
                width:  20; height: 20
                active:        root.isListening || root.isThinking || root.query !== ""
                thinkingPhase: root.thinkingPhase
                morphColor:    root._lockedBreathingRune
                               ? Qt.color(root._lockedBreathingRune.color)
                               : root.morphColor
                // Hide when a breathing style is locked — style icon takes over
                visible: root._lockedBreathingRune === null
                opacity: root._lockedBreathingRune === null ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
            }

            // Locked breathing style sigil — crystallizes over the ring
            Text {
                anchors.centerIn: parent
                visible: root._lockedBreathingRune !== null
                opacity: root._lockedBreathingRune !== null ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180 } }
                text: {
                    if (!root._lockedBreathingRune) return ""
                    var id = root._lockedBreathingRune.id || ""
                    if (id === "sun")       return "☀"
                    if (id === "moon")      return "☽"
                    if (id === "celestial") return "✧"
                    if (id === "star")      return "✧"
                    return root._lockedBreathingRune.icon || "◈"
                }
                color: root._lockedBreathingRune
                       ? Qt.color(root._lockedBreathingRune.color)
                       : root.morphColor
                font.pixelSize: 16
                Behavior on color { ColorAnimation { duration: 200 } }
            }

            // Radial glow — always present, color follows locked style or morphColor
            Rectangle {
                anchors.fill: parent; radius: 10
                color: root._lockedBreathingRune
                       ? Qt.color(root._lockedBreathingRune.color)
                       : root.morphColor
                opacity: 0.12
                Behavior on color { ColorAnimation { duration: 300 } }
                layer.enabled: true
                layer.effect: MultiEffect { blurEnabled: true; blur: 1.0; blurMax: 16 }
            }
        }

        // ── INPUT AREA ───────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            // Translated intent ghost (shown when no query yet)
            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.translatedIntent !== "" && root.query === ""
                text:  root.translatedIntent
                color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.35)
                font.family:    "Fira Code"
                font.pixelSize: 15
                font.italic:    true
            }

            // Prediction underlay — full completion shown behind transparent input
            Text {
                id: predictionUnderlay
                anchors.verticalCenter: parent.verticalCenter
                x: lockedTokensRow.visible ? lockedTokensRow.implicitWidth + 12 : 0
                visible: root.prediction !== "" && root.query !== "" &&
                         root.prediction.toLowerCase().startsWith(root.query.toLowerCase())
                text:  root.prediction
                color: Qt.rgba(1, 1, 1, 0.10)
                font.family:    "Fira Code"
                font.pixelSize: 16
                z: 0
            }

            // ── Locked rune chips — Tab-cast NLU segments ───────────────
            Row {
                id: lockedTokensRow
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                visible: root.lockedTokens.length > 0

                Repeater {
                    id: _runeRepeater
                    model: root.lockedTokens

                    delegate: RuneChip {
                        required property var  modelData
                        required property int  index
                        runeData: modelData
                        isLast:   index === root.lockedTokens.length - 1

                        onShatterComplete: {
                            // Remove this rune from the array after shatter finishes
                            // (shatter is triggered externally via shatterLastToken)
                        }
                    }
                }
            }

            // Ghost suffix — GhostText
            GhostText {
                id: ghostLayer
                anchors.verticalCenter: parent.verticalCenter
                x: commandInput.cursorRectangle.x
                width:  parent.width
                height: parent.height

                ghostText:    root.ghostText
                prediction:   root.prediction
                confidence:   ghostText !== ""
                              ? Math.min(1.0, 0.4 + (1.0 - ghostText.length / 20.0) * 0.6)
                              : 0.0
                morphColor:   root.morphColor
                fontFamily:   "Fira Code"
                fontSize:     16
            }

            // ── Ghost chip preview — shown when NLU has a pending rune ────
            // Renders a translucent version of the rune chip at the cursor,
            // pulsing softly to signal "Tab to lock". Disappears on lock/clear.
            Item {
                id: _ghostChipPreview
                anchors.verticalCenter: parent.verticalCenter
                // Position just after the typed text — same anchor as ghostLayer
                x: commandInput.cursorRectangle.x + 6
                visible: root.hasPendingRune && root.pendingRune !== null
                opacity: root.hasPendingRune ? 1.0 : 0.0
                Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

                // Size mirrors a real RuneChip — content-driven
                implicitWidth:  _ghostChipRow.implicitWidth + 18
                implicitHeight: 22
                width:  implicitWidth
                height: implicitHeight

                readonly property color _gc: root.pendingRune
                    ? Qt.color(root.pendingRune.color || "#00B4D8")
                    : Qt.color("#00B4D8")

                // Pulsing border — breathes 0.18 → 0.45 on 1.4s cycle
                property real _pulse: 0.18
                SequentialAnimation on _pulse {
                    loops: Animation.Infinite
                    running: root.hasPendingRune
                    NumberAnimation { to: 0.45; duration: 700; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 0.18; duration: 700; easing.type: Easing.InOutSine }
                }

                // Ghost body
                Rectangle {
                    anchors.fill: parent
                    radius: 6
                    color:  Qt.rgba(_ghostChipPreview._gc.r,
                                    _ghostChipPreview._gc.g,
                                    _ghostChipPreview._gc.b, 0.07)
                    border.color: Qt.rgba(_ghostChipPreview._gc.r,
                                          _ghostChipPreview._gc.g,
                                          _ghostChipPreview._gc.b,
                                          _ghostChipPreview._pulse)
                    border.width: 1
                }

                // Ghost content
                Row {
                    id: _ghostChipRow
                    anchors.centerIn: parent
                    spacing: 5

                    Text {
                        text:  root.pendingRune ? (root.pendingRune.icon || "◈") : "◈"
                        color: Qt.rgba(_ghostChipPreview._gc.r,
                                       _ghostChipPreview._gc.g,
                                       _ghostChipPreview._gc.b, 0.55)
                        font.pixelSize: 12
                        anchors.verticalCenter: parent.verticalCenter
                    }
                    Text {
                        text:  root.pendingRune ? (root.pendingRune.label || "") : ""
                        color: Qt.rgba(1, 1, 1, 0.40)
                        font.family:    "Fira Code"
                        font.pixelSize: 12
                        font.bold:      true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            // ── Inline lex — REVIVED (2026-10-25, her author's
            // word). The crystallized-syntax layer was removed
            // when the Rune system replaced it; it returns as a
            // tint layer riding exactly over the input's glyphs:
            // segments she recognizes wear their colours (a rune
            // its fold accent, a target the registry's emerald,
            // a flag the sage's amber, a path her water, a quote
            // the mirror's violet) and everything else stays
            // transparent, so the line's own white shows through.
            // The chips still lock above; the lex colours inline.
            Text {
                id: lexLayer
                z: 5
                anchors.verticalCenter: parent.verticalCenter
                x: lockedTokensRow.visible ? lockedTokensRow.implicitWidth + 12 : 0
                width: parent.width - x
                textFormat: Text.RichText
                wrapMode: Text.NoWrap
                text: root._lexHtml(root.query)
                font.family: "Fira Code"
                font.pixelSize: 16
            }

            // Actual TextField
            TextField {
                id: commandInput
                anchors.fill: parent
                background: Item {}
                font.family:    "Fira Code"
                font.pixelSize: 16
                color: "#ffffffe6"
                leftPadding: lockedTokensRow.visible ? lockedTokensRow.width + 12 : 0
                placeholderText: {
                    if (root.abyssMode) return "Enter shell command…"
                    if (root.isAtelierActive) return "Enter shell command…"
                    if (root.portalHint === "/") return "/ — filter commands…"
                    if (root.portalHint === "@") return "@ — applets…"
                    if (root.isMacro)     return "Enter sigil parameters…"
                    if (TW.SiMOrchestrator.driveMode === "sun") return "☀  sun — work and files ride first"
                    if (TW.SiMOrchestrator.driveMode === "celestial") return "✧  celestial — games and media ride first"
                    return "∿  speak or command"
                }
                placeholderTextColor: Qt.rgba(1, 1, 1, 0.18)
                verticalAlignment:    TextInput.AlignVCenter
                selectByMouse: true

                // The fall follows the caret itself, not only
                // the keystroke — arrow and click moves shed
                // their ember too (his word, 2026-10-25).
                onCursorPositionChanged: root.spawnEmber()

                // Dynamic Focus Jump
                onVisibleChanged: if (visible) commandInput.forceActiveFocus();
                Component.onCompleted: commandInput.forceActiveFocus();

                onTextChanged: {
                    root.query = text
                    root.textEdited(text)
                    TW.SiMOrchestrator.recordKeystroke()
                    // (Embers ride onCursorPositionChanged —
                    // the fall follows the caret, one trigger.)

                    // High-APM thermal sparks
                    if (TW.SiMOrchestrator.apmHeat > 90) {
                        var now = Date.now()
                        if (now - root._lastSparkTime > 200) {
                            root.spawnSpark()
                            root._lastSparkTime = now
                        }
                    }
                    
                    // Rune reading (the registry answers where the
                    // neural classifier used to — the port's hand).
                    // Her ghost completes rune names first; when no
                    // rune answers, the resolver's own top answer
                    // completes the word (ghostSource, fed by the
                    // Obelisk from her controller).
                    var intent = Runes.RuneRegistry.classify(text)
                    root._registryGhost = Runes.RuneRegistry.ghostText(text)
                    root.ghostText = root._registryGhost !== ""
                        ? root._registryGhost : root.ghostSource
                    
                    if (intent.rune && intent.confidence >= 0.8) {
                        root.hasPendingRune = true
                        root.pendingRune = intent.rune
                    } else {
                        root.hasPendingRune = false
                        root.pendingRune = null
                    }
                }

                Keys.onPressed: function(event) {
                    if (event.key === Qt.Key_Escape)  { event.accepted = true; root.escPressed(); return }
                    // Readline grammar (2026-10-25): the launcher
                    // keeps no PTY, so the Grimoire passthrough
                    // that held Ctrl+C/L/U is stood down and the
                    // hands' home row is honored instead — Ctrl+C
                    // is copy again, untouched below.
                    if (event.modifiers & Qt.ControlModifier) {
                        if (event.key === Qt.Key_J || event.key === Qt.Key_N) { event.accepted = true; root.arrowDown(); return }
                        if (event.key === Qt.Key_K || event.key === Qt.Key_P) { event.accepted = true; root.arrowUp(); return }
                        if (event.key === Qt.Key_Down) { event.accepted = true; root.sectionNext(); return }
                        if (event.key === Qt.Key_Up)   { event.accepted = true; root.sectionPrev(); return }
                        if (event.key === Qt.Key_U) { event.accepted = true; commandInput.text = ""; return }
                        if (event.key === Qt.Key_L) { event.accepted = true; commandInput.text = ""; root.lockedTokens = []; return }
                        if (event.key === Qt.Key_W) { event.accepted = true; root._deleteWordBack(); return }
                        if (event.key === Qt.Key_A) { event.accepted = true; commandInput.cursorPosition = 0; commandInput.deselect(); return }
                        if (event.key === Qt.Key_E) { event.accepted = true; commandInput.cursorPosition = commandInput.text.length; commandInput.deselect(); return }
                    }
                    if (event.key === Qt.Key_Tab) {
                        event.accepted = true
                        if (root.radialAvailable) {
                            root.tabPressed()
                            return
                        }
                        if (root.hasPendingRune) {
                            root.lockPendingRune()
                            return
                        }
                        if (root.ghostText !== "") {
                            root.ghostAccepted()
                            return
                        }
                        root.tabPressed()
                        return
                    }
                    // Backspace on empty input — shatter last locked token,
                    // or clear locked breathing style if no chips remain
                    if (event.key === Qt.Key_Backspace && root.query === "") {
                        event.accepted = true
                        if (root.lockedTokens.length > 0) {
                            root.shatterLastToken()
                        } else {
                            root.styleCleared()
                        }
                        return
                    }
                    if (event.key === Qt.Key_Up)      { event.accepted = true; root.arrowUp(); return }
                    if (event.key === Qt.Key_Down)    { event.accepted = true; root.arrowDown(); return }
                    if (event.key === Qt.Key_PageDown) { event.accepted = true; root.sectionNext(); return }
                    if (event.key === Qt.Key_PageUp)   { event.accepted = true; root.sectionPrev(); return }
                    // Left/Right are the caret's own — never eaten.
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                        event.accepted = true
                        if (root.query.trim() === "" && root.lockedTokens.length === 0) return
                        if (root.hasCollision || root.showGuardian) return
                        root.executeRequested()
                    }
                    // Hotkey selection (⌘1-⌘9)
                    if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.MetaModifier) {
                        if (event.key >= Qt.Key_0 && event.key <= Qt.Key_9) {
                            event.accepted = true
                            var num = event.key - Qt.Key_0
                            if (num === 0) num = 10  // ⌘0 = 10th item
                            root.numberPressed(num)
                            return
                        }
                        if (event.key === Qt.Key_S) {
                            event.accepted = true
                            root.stealthToggled()
                            return
                        }
                    }
                }
            }
        }

        // ── RIGHT SIDE ───────────────────────────────────────────────
        RowLayout {
            spacing: 10
            Layout.alignment: Qt.AlignVCenter

            // Cognitive waveform pulse
            Row {
                spacing: 2
                visible: root.obeliskMode === "cognitive" && root.isListening
                Layout.alignment: Qt.AlignVCenter
                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 2; radius: 1; color: root.morphColor
                        height: 4 + Math.random() * 8
                        SequentialAnimation on height {
                            loops: Animation.Infinite; running: root.isListening
                            NumberAnimation { to: 4 + Math.random() * 10; duration: 200 + index * 100 }
                            NumberAnimation { to: 4; duration: 200 + index * 100 }
                        }
                    }
                }
            }

            // Listening pulse dot
            Rectangle {
                width: 6; height: 6; radius: 3
                color:   root.morphColor
                visible: root.isListening && root.obeliskMode !== "cognitive"
                SequentialAnimation on opacity {
                    loops: Animation.Infinite; running: root.isListening && root.obeliskMode !== "cognitive"
                    NumberAnimation { to: 0.2; duration: 500 }
                    NumberAnimation { to: 1.0; duration: 500 }
                }
            }

            // Intent badge — standalone pill, right side of lens
            IntentBadge {
                Layout.alignment:  Qt.AlignVCenter
                morphColor:        root.morphColor
                lockedStyleName:   root._lockedStyleName
                lockedStyleColor:  root._lockedBreathingRune
                                   ? Qt.color(root._lockedBreathingRune.color)
                                   : root.morphColor
                styleIsLocked:     root._lockedBreathingRune !== null
                liveContext:       root.liveContext
                intentPending:     root.intentPending
                intentDescription: root.intentDescription
                intentConfidence:  root.intentConfidence
                modeBadge:         root.modeBadge
            }
        }
    }

    // Sync TextField when query is cleared externally
    onQueryChanged: {
        if (query === "" && commandInput.text !== "")
            commandInput.text = ""
    }

    // Ctrl+W's hand: erase the word standing before the caret.
    function _deleteWordBack() {
        var t = commandInput.text
        var pos = commandInput.cursorPosition
        if (pos === 0) return
        var i = pos
        while (i > 0 && t.charAt(i - 1) === " ") i--
        while (i > 0 && t.charAt(i - 1) !== " ") i--
        commandInput.remove(i, pos)
    }

    function focusInput() { commandInput.forceActiveFocus() }
    function clear()      { query = ""; commandInput.text = "" }
    function setText(t)   { commandInput.text = t }
    function triggerExecutePulse() {
        _executePulse = 1.0
        executePulseDecay.restart()
    }
    function triggerCrystallize() { ghostLayer.startCrystallize() }
    function triggerShatter()     { ghostLayer.startShatter() }

    // ── Inline result strip — sits below the lens, no layout shift ────
    Rectangle {
        anchors.top:              parent.bottom
        anchors.topMargin:        6
        anchors.left:             parent.left
        anchors.right:            parent.right
        height:                   inlineResultText.implicitHeight + 14
        radius:                   8
        visible:                  root.inlineResult !== ""
        opacity:                  visible ? 1.0 : 0.0
        color:                    Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.06)
        border.color:             Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.22)
        border.width:             1
        Behavior on opacity { NumberAnimation { duration: 220 } }

        Text {
            id: inlineResultText
            anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: 12 }
            text:  root.inlineResult
            color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.85)
            font { family: "3270 Nerd Font Mono, Fira Code"; pixelSize: 10 }
            font.letterSpacing: 1
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
}
