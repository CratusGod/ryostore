/* =====================================================================
 * CrystalShimmer.qml — Crystallization ShaderEffect Overlay
 *
 * Renders the ice crystal formation and shatter burst.
 * Driven by crystallizationProgress (Tab hold) and shatterProgress.
 * Uses crystallize.frag.qsb — compile with compile_shaders.sh.
 * ===================================================================== */
import QtQuick

Item {
    id: root

    property real  crystallizationProgress: 0.0
    property real  shatterProgress:         0.0
    property real  confidence:              0.0
    property color morphColor:              "#00B4D8"
    property real  time:                    0.0

    // Shader is compiled and available
    readonly property bool _shaderAvailable: true

    // ── QML fallback — DISABLED when shader is available for performance ──
    Item {
        anchors.fill: parent
        visible: false  // Always disabled - shader is always available

        // Crystal facet lines — Canvas approximation
        Canvas {
            id: fallbackCanvas
            anchors.fill: parent
            opacity: root.crystallizationProgress * 0.7

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                if (root.crystallizationProgress < 0.01) return

                var prog = root.crystallizationProgress
                var col  = root.morphColor.toString()

                // Draw crystal facet lines spreading from left
                ctx.strokeStyle = col
                ctx.lineWidth   = 0.5
                ctx.globalAlpha = prog * 0.6

                var spread = width * prog
                var steps  = Math.floor(prog * 12)
                for (var i = 0; i < steps; i++) {
                    var x  = (i / steps) * spread
                    var y1 = height * (0.1 + Math.sin(i * 1.7 + root.time) * 0.15)
                    var y2 = height * (0.9 - Math.sin(i * 2.3 + root.time) * 0.15)
                    ctx.beginPath()
                    ctx.moveTo(x, y1)
                    ctx.lineTo(x + 8, height / 2)
                    ctx.lineTo(x, y2)
                    ctx.stroke()
                }
                ctx.globalAlpha = 1.0
            }

            Connections {
                target: root
                function onCrystallizationProgressChanged() { fallbackCanvas.requestPaint() }
                function onTimeChanged() {
                    if (root.crystallizationProgress > 0.01) fallbackCanvas.requestPaint()
                }
            }
        }

        // Shatter burst — radial rings
        Repeater {
            model: root.shatterProgress > 0.01 ? 3 : 0
            delegate: Rectangle {
                required property int index
                anchors.centerIn: parent
                width:  (root.shatterProgress * (parent.width * 1.4)) * (0.6 + index * 0.25)
                height: width; radius: width / 2
                color:  "transparent"
                border.color: root.morphColor
                border.width: 1
                opacity: root.shatterProgress * (0.6 - index * 0.15)
                Behavior on width   { NumberAnimation { duration: 16 } }
                Behavior on opacity { NumberAnimation { duration: 16 } }
            }
        }
    }

    // ── Shader path — active after qsb compile ────────────────────────
    ShaderEffect {
        anchors.fill: parent
        visible: root._shaderAvailable

        property real u_time:       root.time
        property real u_confidence: root.confidence
        property real u_progress:   root.crystallizationProgress
        property real u_shatter:    root.shatterProgress
        property real u_morphR:     root.morphColor.r
        property real u_morphG:     root.morphColor.g
        property real u_morphB:     root.morphColor.b
        property real u_width:      width
        property real u_height:     height

        fragmentShader: "../../shaders/crystallize.frag.qsb"
        blending: true

        // Entrance animation — scale in when first visible
        scale: 0.95
        opacity: 0.0
        Component.onCompleted: {
            if (root.crystallizationProgress > 0.01 || root.shatterProgress > 0.01) {
                entranceAnim.start()
            }
        }
        onVisibleChanged: {
            if (visible && (root.crystallizationProgress > 0.01 || root.shatterProgress > 0.01)) {
                entranceAnim.start()
            }
        }

        SequentialAnimation {
            id: entranceAnim
            ParallelAnimation {
                NumberAnimation {
                    target: parent; property: "scale"
                    from: 0.92; to: 1.0; duration: 220
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: parent; property: "opacity"
                    from: 0.0; to: 1.0; duration: 180
                }
            }
        }
    }
}
