/* =====================================================================
 * GhostText.qml — Prediction Overlay · Crystallization Host · Cursor
 *
 * Pure visual overlay — zero layout footprint.
 * Renders ghost text (suffix prediction), crystal effects, and the
 * phasing cursor bar (formerly CursorBridge).
 *
 * States:
 *   ghost       — faded prediction text, subtle shimmer
 *   coalesce    — high confidence, text sharpens + blur reduces
 *   crystallize — Tab held, ice crystals spread from cursor
 *   shatter     — execute / Tab release, burst then clear
 * ===================================================================== */
import QtQuick
import QtQuick.Effects

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────
    property string ghostText:    ""   // suffix after current input
    property string prediction:   ""   // full-word underlay
    property real   confidence:   0.0  // 0–1, drives coalesce brightness
    property color  morphColor:   "#00B4D8"
    property string fontFamily:   "3270 Nerd Font Mono, Fira Code"
    property int    fontSize:     13

    // ── Unified State Machine ───────────────────────────────────────────
    // State constants: 0=Idle, 1=Ghost, 2=Coalesce, 3=Crystallize, 4=Shatter
    // (enum is not valid QML syntax — use plain integer comparisons)
    property int _state: 0
    property real _stateProgress: 0.0  // 0-1 for current state transition

    // Public properties for backward compatibility
    property real crystallizationProgress: _state === 3 ? _stateProgress : 0.0
    property real shatterProgress:         _state === 4 ? _stateProgress : 0.0
    property bool isCoalescing: _state === 2 || (_state === 1 && ghostText.length <= 8)


    // ── Zero layout footprint — pure overlay ──────────────────────────
    implicitWidth:  0
    implicitHeight: 0
    clip:           false

    // ── Derived ───────────────────────────────────────────────────────
    readonly property bool hasContent: ghostText !== "" || prediction !== ""
    readonly property real _ghostAlpha: {
        if (root._state === 4) return 0.0   // Shatter
        if (root._state === 3) return 0.0   // Crystallize
        // Inline completion: higher opacity so it reads as text already typed.
        // Coalesce (high confidence) pushes toward 0.65 — nearly solid.
        return root.isCoalescing
            ? 0.45 + confidence * 0.20   // coalescing: 45–65%
            : 0.28 + confidence * 0.18   // ghost: 28–46% — inline, not floating
    }

    visible: hasContent || root._state !== 0

    // Update state based on ghost text changes
    onGhostTextChanged: {
        if (ghostText !== "" && root._state === 0) _transitionTo(1)   // Idle → Ghost
        if (ghostText === "" && root._state === 1) _transitionTo(0)   // Ghost → Idle
    }

    // ── State update function (called from parent animation loop) ───────
    function updateState(dt) {
        if (root._stateProgress < 1.0) {
            var speed = 0.03 * (dt / 0.016)
            if (root._state === 4) speed = 0.12 * (dt / 0.016)  // Shatter faster
            root._stateProgress = Math.min(1.0, root._stateProgress + speed)
        }
        // Auto-transition: Ghost → Idle when text clears
        if (root._state === 1 && root.ghostText === "") _transitionTo(0)
        // Auto-transition: Shatter → Idle when complete
        if (root._state === 4 && root._stateProgress >= 1.0) _transitionTo(0)
    }

    function _transitionTo(newState) {
        if (_state === newState) return
        _state = newState
        _stateProgress = 0.0
    }

    function startCrystallize() { _transitionTo(3) }
    function startShatter()     { _transitionTo(4) }
    function resetToGhost() {
        _transitionTo(root.ghostText !== "" ? 1 : 0)
    }

    // ── Ghost text — inline suffix completion ────────────────────────
    // Non-italic, same font as input — reads as "already typed, not committed".
    // Positioned at cursor x (set by parent), so re + con = re|con inline.
    Text {
        id: ghostLabel
        anchors { left: parent.left; verticalCenter: parent.verticalCenter }
        text:    root.ghostText
        font   { family: root.fontFamily; pixelSize: root.fontSize }
        color:   root.morphColor
        opacity: root._ghostAlpha
        visible: root.ghostText !== "" && root._state === 1

        layer.enabled: visible && root._ghostAlpha > 0.01
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor:   Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.35)
            shadowBlur:    0.70
            blurEnabled:   false
        }
    }

    // ── Crystal shimmer overlay ───────────────────────────────────────
    CrystalShimmer {
        id: shimmer
        anchors.fill: parent
        crystallizationProgress: root.crystallizationProgress
        shatterProgress:         root.shatterProgress
        confidence:              root.confidence
        morphColor:              root.morphColor
        time:                    root._shaderTime || 0.0
        visible: root.crystallizationProgress > 0.01 || root.shatterProgress > 0.01
    }

    // Expose shader time from parent animation loop
    property real _shaderTime: 0.0
}
