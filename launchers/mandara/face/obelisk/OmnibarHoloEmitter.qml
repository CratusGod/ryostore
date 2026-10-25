/* OmnibarHoloEmitter.qml
 * Holographic IP Emitter — shown above the input when an IP is detected.
 * Rotating orbital ring + pulse dot + TARGET_INTEL badge + connector line.
 * Mirrors HolographicEmitter in the TSX.
 */
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string detectedIp: ""

    visible:  detectedIp !== ""
    opacity:  visible ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 200 } }

    implicitWidth:  120
    implicitHeight: 160 + 40

    // ── ORBITAL RING ─────────────────────────────────────────────────
    Rectangle {
        id: orbitalRing
        width: 80; height: 80
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        radius: 40
        color: "transparent"
        border.color: "#22d3ee40"
        border.width: 1

        RotationAnimator on rotation {
            from: 0; to: 360
            duration: 8000
            loops: Animation.Infinite
            running: root.visible
        }

        // Inner pulse dot
        Rectangle {
            width: 6; height: 6; radius: 3
            anchors.centerIn: parent
            color: "#22d3ee"
            SequentialAnimation on opacity {
                loops: Animation.Infinite
                running: root.visible
                NumberAnimation { to: 0.2; duration: 800 }
                NumberAnimation { to: 1.0; duration: 800 }
            }
        }
    }

    // ── TARGET_INTEL BADGE ───────────────────────────────────────────
    Rectangle {
        anchors.top: orbitalRing.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        width:  ipLabel.implicitWidth + 16
        height: 22
        radius: 6
        color:  "#0a1a2a"
        border.color: "#22d3ee40"
        border.width: 1

        Text {
            id: ipLabel
            anchors.centerIn: parent
            text:  "TARGET_INTEL: " + root.detectedIp
            color: "#22d3ee"
            font.pixelSize:   8
            font.letterSpacing: 3
            font.bold: true
            font.family: "monospace"
        }
    }

    // ── CONNECTOR LINE ───────────────────────────────────────────────
    Rectangle {
        anchors.top: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: 1; height: 24
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#22d3ee80" }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }
}
