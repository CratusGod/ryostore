/* OmnibarRadialMenu.qml
 * Full-screen IP action radial wheel.
 * Opened by Tab when an IP is detected in the query.
 * Mirrors RadialMenuOverlay in the TSX.
 */
import QtQuick
import QtQuick.Effects

Rectangle {
    id: root

    property string targetIp: ""

    signal actionSelected(string cmd)
    signal closed()

    visible: false
    focus:   true
    color:   Qt.alpha("#f20000", 0)
    z:       10

    // Click outside wheel to close
    MouseArea {
        anchors.fill: parent
        onClicked:    root.closed()
    }

    // ── WHEEL ────────────────────────────────────────────────────────
    Item {
        id: wheel
        width: 500; height: 500
        anchors.centerIn: parent

        // Absorb clicks inside wheel
        MouseArea { anchors.fill: parent; onClicked: {} }

        // Orbital path rings
        Canvas {
            anchors.fill: parent
            opacity: 0.10
            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.strokeStyle = "white"
                ctx.lineWidth = 1
                ctx.setLineDash([4, 4])
                ctx.beginPath()
                ctx.arc(250, 250, 140, 0, Math.PI * 2)
                ctx.stroke()
                ctx.setLineDash([8, 8])
                ctx.beginPath()
                ctx.arc(250, 250, 190, 0, Math.PI * 2)
                ctx.stroke()
            }
        }

        // Central IP badge
        Rectangle {
            anchors.centerIn: parent
            width:  ipCenterLabel.implicitWidth + 32
            height: 48
            radius: 16
            color:  Qt.alpha("#10b981", 0.094)
            border.color: Qt.alpha("#10b981", 0.4)
            border.width: 1
            z: 2

            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor:   Qt.alpha("#10b981", 0.251)
                shadowBlur:    0.8
            }

            Text {
                id: ipCenterLabel
                anchors.centerIn: parent
                text:  root.targetIp
                color: "#10b981"
                font.pixelSize: 20
                font.bold:      true
                font.family:    "monospace"
            }
        }

        // Four radial action nodes
        Repeater {
            model: [
                { label: "DEEP SCAN", angle: 270, cmd: "/recon "           },
                { label: "EXPLOIT",   angle: 0,   cmd: "/strike:exploit "  },
                { label: "MONITOR",   angle: 90,  cmd: "/strike:monitor "  },
                { label: "FUZZ",      angle: 180, cmd: "/strike:nuclei "   }
            ]

            delegate: Rectangle {
                property real rad: modelData.angle * Math.PI / 180
                x: wheel.width  / 2 + Math.cos(rad) * 190 - width  / 2
                y: wheel.height / 2 + Math.sin(rad) * 190 - height / 2

                width: 88; height: 88; radius: 44
                color:        nodeHover.containsMouse ? Qt.alpha("#ffffff", 0.051) : Qt.alpha("#0a0a0a", 0.6)
                border.color: nodeHover.containsMouse ? Qt.alpha("#ffffff", 0.302) : Qt.alpha("#ffffff", 0.051)
                border.width: 1

                Behavior on color        { ColorAnimation { duration: 150 } }
                Behavior on border.color { ColorAnimation { duration: 150 } }

                Text {
                    anchors.centerIn: parent
                    text:  modelData.label
                    color: nodeHover.containsMouse ? "#ffffff" : Qt.alpha("#ffffff", 0.302)
                    font.pixelSize:   9
                    font.bold:        true
                    font.letterSpacing: 2
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    width: parent.width - 8
                    Behavior on color { ColorAnimation { duration: 150 } }
                }

                Rectangle {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: 14
                    width: 4; height: 4; radius: 2
                    color: nodeHover.containsMouse ? "#10b981" : Qt.alpha("#ffffff", 0.063)
                    Behavior on color { ColorAnimation { duration: 150 } }
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0.3; duration: 700 }
                        NumberAnimation { to: 1.0; duration: 700 }
                    }
                }

                MouseArea {
                    id: nodeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape:  Qt.PointingHandCursor
                    onClicked: {
                        root.actionSelected(modelData.cmd + root.targetIp)
                        root.closed()
                    }
                }
            }
        }

        // Abort label
        Text {
            anchors.top:   parent.top
            anchors.right: parent.right
            text:  "ABORT_EXPANSION [Esc]"
            color: Qt.alpha("#ffffff", 0.125)
            font.pixelSize:   9
            font.bold:        true
            font.letterSpacing: 4
        }
    }

    Keys.onPressed: function(event) {
        if (event.key === Qt.Key_Escape) {
            event.accepted = true
            root.closed()
        }
    }
}
