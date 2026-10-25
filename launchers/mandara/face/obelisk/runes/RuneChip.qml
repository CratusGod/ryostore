/* =====================================================================
 * RuneChip.qml — Crystallized Rune Token
 *
 * A locked rune segment in the Obelisk input bar.
 * Each chip is a small crystal — SDF crystallize shader plays on
 * entrance, SDF shatter plays on removal (Backspace).
 *
 * Props:
 *   runeData  — { id, label, icon, color, cmd, terminal }
 *   isLast    — true when this is the most recently locked rune
 *               (gets brighter border + active glow)
 *
 * Signals:
 *   shatterComplete — emitted when the shatter animation finishes
 * ===================================================================== */
import QtQuick
import QtQuick.Effects

Item {
    id: root

    property var  runeData: ({ id: "", label: "", icon: "◈", color: "#00B4D8", cmd: "", terminal: false })
    property bool isLast:   false

    signal shatterComplete()

    // ── Derived ───────────────────────────────────────────────────────
    readonly property color _runeColor: Qt.color(runeData.color || "#00B4D8")

    // ── Geometry — _chipRow is a direct child so implicitWidth resolves ─
    implicitWidth:  _chipRow.implicitWidth + 18
    implicitHeight: 24

    // ── Shader state ──────────────────────────────────────────────────
    property real _crystalProg: 0.0
    property real _shatterProg: 0.0
    property real _shimmerTime: 0.0

    NumberAnimation on _crystalProg {
        id: _entranceAnim
        from: 0.0; to: 1.0; duration: 280
        easing.type: Easing.OutCubic
        running: false
    }

    NumberAnimation on _shatterProg {
        id: _shatterAnim
        from: 0.0; to: 1.0; duration: 320
        easing.type: Easing.OutCubic
        running: false
        onFinished: root.shatterComplete()
    }

    // Idle shimmer clock — ticks only when fully formed and not shattering
    Timer {
        interval: 33; repeat: true
        running:  root._crystalProg >= 1.0 && root._shatterProg < 0.01
        onTriggered: root._shimmerTime += 0.033
    }

    function crystallize() { _crystalProg = 0.0; _entranceAnim.restart() }
    function shatter()     { _shatterAnim.restart() }

    Component.onCompleted: crystallize()

    // ── Shared fade — body + text fade together during shatter ────────
    readonly property real _fadeAlpha: root._shatterProg > 0.0
        ? Math.max(0.0, 1.0 - root._shatterProg * 2.2)
        : 1.0

    // ── Chip body ─────────────────────────────────────────────────────
    Rectangle {
        id: _body
        anchors.fill: parent
        radius: 6
        opacity: root._fadeAlpha

        color: Qt.rgba(root._runeColor.r, root._runeColor.g, root._runeColor.b,
                       0.10 + root._crystalProg * 0.04)
        border.color: Qt.rgba(root._runeColor.r, root._runeColor.g, root._runeColor.b,
                               root.isLast ? 0.75 : 0.40)
        border.width: 1

        Behavior on border.color { ColorAnimation { duration: 120 } }
        Behavior on opacity      { NumberAnimation { duration: 60  } }

        layer.enabled: root.isLast
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor:   Qt.rgba(root._runeColor.r, root._runeColor.g, root._runeColor.b, 0.55)
            shadowBlur:    0.70
            blurEnabled:   false
        }
    }

    // ── Chip content row — direct child of root ───────────────────────
    Row {
        id: _chipRow
        anchors.centerIn: parent
        spacing: 5
        z: 2
        opacity: root._fadeAlpha
        Behavior on opacity { NumberAnimation { duration: 60 } }

        Text {
            text:  root.runeData.icon || "◈"
            color: root._runeColor
            font.pixelSize: 13
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text:  root.runeData.label || ""
            color: Qt.rgba(1, 1, 1, 0.88)
            font.family:    "Fira Code"
            font.pixelSize: 13
            font.bold:      true
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    // ── SDF Crystal shader — entrance crystallize + shatter burst ─────
    ShaderEffect {
        id: _shader
        anchors.fill: parent
        z: 1
        visible: root._crystalProg < 1.0 || root._shatterProg > 0.01

        property real u_time:       root._shimmerTime
        property real u_confidence: 0.85
        property real u_progress:   root._crystalProg
        property real u_shatter:    root._shatterProg
        property real u_morphR:     root._runeColor.r
        property real u_morphG:     root._runeColor.g
        property real u_morphB:     root._runeColor.b
        property real u_width:      width
        property real u_height:     height

        fragmentShader: "../../shaders/crystallize.frag.qsb"
        blending: true
    }

    // ── Idle shimmer — subtle living-crystal effect when fully formed ──
    ShaderEffect {
        id: _idleShimmer
        anchors.fill: parent
        z: 1
        visible: root._crystalProg >= 1.0 && root._shatterProg < 0.01
        opacity: 0.28

        property real u_time:       root._shimmerTime
        property real u_confidence: 0.35 + (root.isLast ? 0.25 : 0.0)
        property real u_progress:   0.55
        property real u_shatter:    0.0
        property real u_morphR:     root._runeColor.r
        property real u_morphG:     root._runeColor.g
        property real u_morphB:     root._runeColor.b
        property real u_width:      width
        property real u_height:     height

        fragmentShader: "../../shaders/crystallize.frag.qsb"
        blending: true
    }
}
