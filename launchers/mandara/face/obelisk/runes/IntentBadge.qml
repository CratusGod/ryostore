/* IntentBadge.qml — Obelisk Intent & Mode Badge
 * ================================================
 * Standalone pill that lives on the right side of InputLens.
 * Shows the system's live understanding of what the operator is doing.
 *
 * Priority (highest → lowest):
 *   1. Locked breathing style  — FLAME / WATER / INSECT etc.
 *   2. Live context            — tool executing
 *   3. Intent pending          — ∿ ...
 *   4. Intent description      — NLU confident match (≥ 0.5)
 *   5. Mode badge              — [@] [~] [FORGE] [SYSTEM] [?]
 *   6. Empty                   — nothing to show, pill collapses
 *
 * Shader: crystallize entrance fires on every content change.
 *         Idle shimmer runs while a breathing style is locked.
 *
 * Color:
 *   locked style  → style accent (TW.styleAccents)
 *   live context  → violet
 *   confidence ≥ 0.8 → EYE green
 *   confidence ≥ 0.5 → sovereign amber
 *   confidence > 0   → breach red
 *   default          → morphColor
 */
import QtQuick
import QtQuick.Effects
import "../../tw" as TW

Item {
    id: root

    // ── Props ─────────────────────────────────────────────────────────
    property color  morphColor:        TW.SiMOrchestrator.accentWater
    property string lockedStyleName:   ""      // "FLAME", "WATER", "" etc.
    property color  lockedStyleColor:  morphColor
    property bool   styleIsLocked:     false
    property string liveContext:       ""
    property bool   intentPending:     false
    property string intentDescription: ""
    property real   intentConfidence:  0.0
    property string modeBadge:         ""

    // ── Derived display text ──────────────────────────────────────────
    readonly property string _displayText: {
        if (lockedStyleName !== "")  return lockedStyleName
        if (liveContext !== "")      return liveContext.toUpperCase()
        if (intentPending)           return "∿ ..."
        if (intentDescription !== "" && intentConfidence >= 0.5)
            return intentDescription.toUpperCase().slice(0, 18)
        if (modeBadge !== "")        return modeBadge.toUpperCase()
        return ""
    }

    readonly property bool _hasContent: _displayText !== ""

    // ── Accent color ──────────────────────────────────────────────────
    readonly property color _accent: {
        if (styleIsLocked)           return lockedStyleColor
        if (liveContext !== "")      return Qt.rgba(0.80, 0.45, 0.85, 1.0)
        if (intentConfidence >= 0.80) return TW.SiMOrchestrator.accentEye
        if (intentConfidence >= 0.50) return TW.SiMOrchestrator.accentSovereign
        if (intentConfidence > 0)    return TW.SiMOrchestrator.accentBreach
        return root.morphColor
    }

    // ── Shader state ──────────────────────────────────────────────────
    property real _crystalProg: 0.0
    property real _shimmerTime: 0.0

    NumberAnimation on _crystalProg {
        id: _entranceAnim
        from: 0.0; to: 1.0; duration: 240
        easing.type: Easing.OutCubic
        running: false
    }

    // Crystallize entrance on every content change
    on_DisplayTextChanged: {
        if (_displayText !== "") {
            _crystalProg = 0.0
            _entranceAnim.restart()
        }
    }

    // Idle shimmer — ticks while style is locked and crystal is formed
    Timer {
        interval: 33; repeat: true
        running:  root.styleIsLocked && root._crystalProg >= 1.0
        onTriggered: root._shimmerTime += 0.033
    }

    // ── Geometry — pill-shaped, content-driven width ──────────────────
    // visible stays true (§16) — height + opacity handle show/hide
    visible:        true
    implicitWidth:  _hasContent ? (_label.implicitWidth + 20) : 0
    implicitHeight: 22
    height:         22
    width:          implicitWidth
    opacity:        _hasContent ? 1.0 : 0.0
    Behavior on opacity       { NumberAnimation { duration: 180 } }
    Behavior on implicitWidth { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

    // ── Pill body ─────────────────────────────────────────────────────
    Rectangle {
        id: _pill
        anchors.fill: parent
        radius: height / 2   // fully pill-shaped

        color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b,
                       0.08 + root._crystalProg * 0.04)
        border.width: 1

        Behavior on color { ColorAnimation { duration: 200 } }

        // Border — pulses when style is locked, static otherwise.
        // Uses _borderAlpha property to avoid §14.6 stacking violation.
        property real _borderAlpha: root.styleIsLocked ? 0.55 : 0.30
        Behavior on _borderAlpha { NumberAnimation { duration: 200 } }

        SequentialAnimation on _borderAlpha {
            loops: Animation.Infinite
            running: root.styleIsLocked
            NumberAnimation { to: 0.75; duration: 900; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.30; duration: 900; easing.type: Easing.InOutSine }
        }

        border.color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b,
                              _pill._borderAlpha + root._crystalProg * 0.15)

        // ── Crystallize entrance ──────────────────────────────────────
        ShaderEffect {
            anchors.fill: parent; z: 1
            visible: root._crystalProg < 1.0 && root._hasContent

            property real u_time:       root._shimmerTime
            property real u_confidence: 0.85
            property real u_progress:   root._crystalProg
            property real u_shatter:    0.0
            property real u_morphR:     root._accent.r
            property real u_morphG:     root._accent.g
            property real u_morphB:     root._accent.b
            property real u_width:      width
            property real u_height:     height

            fragmentShader: "../../shaders/crystallize.frag.qsb"
            blending: true
        }

        // ── Idle shimmer — living crystal while style is locked ───────
        ShaderEffect {
            anchors.fill: parent; z: 1
            visible: root.styleIsLocked && root._crystalProg >= 1.0
            opacity: 0.25

            property real u_time:       root._shimmerTime
            property real u_confidence: 0.35
            property real u_progress:   0.55
            property real u_shatter:    0.0
            property real u_morphR:     root._accent.r
            property real u_morphG:     root._accent.g
            property real u_morphB:     root._accent.b
            property real u_width:      width
            property real u_height:     height

            fragmentShader: "../../shaders/crystallize.frag.qsb"
            blending: true
        }

        // ── Label ─────────────────────────────────────────────────────
        Text {
            id: _label
            anchors.centerIn: parent
            text:  root._displayText
            color: Qt.rgba(root._accent.r, root._accent.g, root._accent.b,
                           root.styleIsLocked ? 0.95 : 0.82)
            font.family:      "Fira Code"
            font.pixelSize:   11
            font.bold:        true
            font.letterSpacing: root.styleIsLocked ? 2.0 : 1.5
            Behavior on color { ColorAnimation { duration: 200 } }
        }
    }
}
