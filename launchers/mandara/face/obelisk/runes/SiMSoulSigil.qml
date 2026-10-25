/* SiMSoulSigil.qml — SiMSoul shader in a fixed-size sigil form
 * ==============================================================
 * Renders the SiMSoul iridescent orb + 7-fold swarm clipped to any square size.
 * Ported from Shigurui Zenith.
 */
import QtQuick
import "../../tw" as TW

Item {
    id: root

    property bool   active:        false
    property string thinkingPhase: "recall"
    property color  morphColor:    TW.SiMOrchestrator.accentSage

    implicitWidth:  64
    implicitHeight: 64

    // ── Derive disciplineHue from morphColor ──────────────────────────
    readonly property real _hue: {
        var c  = root.morphColor
        var r  = c.r, g = c.g, b = c.b
        var mx = Math.max(r, g, b), mn = Math.min(r, g, b), d = mx - mn
        if (d < 0.001) return 0.55
        var h
        if      (mx === r) h = ((g - b) / d + (g < b ? 6 : 0))
        else if (mx === g) h = ((b - r) / d + 2)
        else               h = ((r - g) / d + 4)
        return h / 6.0
    }

    // ── inferring: 0 idle, ramps to 1 on active + phase ──────────────
    readonly property real _inferring: {
        if (!root.active) return 0.0
        if (root.thinkingPhase === "respond") return 1.0
        if (root.thinkingPhase === "reason")  return 0.7
        return 0.4  // recall
    }

    // ── tpsBeat: pulses on respond ────────────────────────────────────
    readonly property real _tpsBeat: (root.active && root.thinkingPhase === "respond") ? 0.6 : 0.0

    // ── Local animation time ──────────────────────────────────────────
    property real _t: 0.0
    NumberAnimation on _t {
        from: 0; to: 100000; duration: 100000000
        loops: Animation.Infinite
        running: root.visible && root.active
    }

    // 1. Gyroscoping Gimbal Rings (Unified with SiMCore)
    Item {
        anchors.fill: parent
        opacity: root.active ? 1.0 : 0.4
        z: 2
        Behavior on opacity { NumberAnimation { duration: 500 } }

        // Ring A (Outer)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            radius: width / 2; color: "transparent"
            border.color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.3)
            border.width: 1.0
            transform: Rotation {
                id: _rotA; origin.x: width / 2; origin.y: height / 2
                axis { x: 1; y: 0.2; z: 0 }
            }
            NumberAnimation {
                target: _rotA; property: "angle"; from: 0; to: 360; loops: Animation.Infinite
                duration: 6000; running: root.visible && root.active
            }
        }

        // Ring B (Mid)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            radius: width / 2; color: "transparent"
            border.color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.2)
            border.width: 1.0
            transform: Rotation {
                id: _rotB; origin.x: width / 2; origin.y: height / 2
                axis { x: 0; y: 1; z: 0.2 }
            }
            NumberAnimation {
                target: _rotB; property: "angle"; from: 360; to: 0; loops: Animation.Infinite
                duration: 4800; running: root.visible && root.active
            }
        }

        // Ring C (Inner)
        Rectangle {
            anchors.centerIn: parent
            width: parent.width; height: parent.height
            radius: width / 2; color: "transparent"
            border.color: Qt.rgba(root.morphColor.r, root.morphColor.g, root.morphColor.b, 0.5)
            border.width: 1.2
            transform: Rotation {
                id: _rotC; origin.x: width / 2; origin.y: height / 2
                axis { x: 0.1; y: 0.1; z: 1 }
            }
            NumberAnimation {
                target: _rotC; property: "angle"; from: 0; to: 360; loops: Animation.Infinite
                duration: 3200; running: root.visible && root.active
            }
        }
    }

    // 2. Clipped Nucleus
    Rectangle {
        anchors.fill: parent
        color:        "transparent"
        clip:         true
        radius:       width / 2   // circular clip
        z: 1

        ShaderEffect {
            width:  parent.width  * 3.5
            height: parent.height * 3.5
            x: -parent.width  * 1.25
            y: -parent.height * 1.25

            property real time:            root._t
            property real tpsBeat:         root._tpsBeat
            property real inferring:       root._inferring
            property real disciplineHue:   root._hue
            property real commandPulse:    0.0
            property real obeliskOpen:     root.active ? 1.0 : 0.0
            property real cursorX:         0.5
            property real cursorY:         0.5
            property real w:               width
            property real h:               height
            property real mistDensity:     1.0
            property real atmospherePhase: 0.0
            property real receivePulse:    0.0

            fragmentShader: "../../shaders/SiMCore.frag.qsb"

            Behavior on inferring { NumberAnimation { duration: 400 } }
            Behavior on tpsBeat   { NumberAnimation { duration: 300 } }
        }
    }
}
