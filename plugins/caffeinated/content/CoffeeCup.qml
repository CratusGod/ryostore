import QtQuick
import QtQuick.Shapes

// A coffee cup drawn in a 24x24 box: cup, handle and saucer always; three
// steam wisps that rise and fade while `steaming`.
Item {
    id: cup

    property color color: "white"
    property bool steaming: false
    property real stroke: 1.8

    readonly property real u: Math.min(width, height) / 24

    implicitWidth: 24
    implicitHeight: 24

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: cup.color
            strokeWidth: cup.stroke * cup.u * 1.0
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            scale: Qt.size(cup.u, cup.u)

            // Cup body: flat rim, sides tapering into a rounded base.
            PathSvg { path: "M4 11h12v3.5a5 5 0 0 1-5 5h-2a5 5 0 0 1-5-5z" }
            // Handle.
            PathSvg { path: "M16 12.5h1.5a2.25 2.25 0 0 1 0 4.5H15.6" }
            // Saucer.
            PathSvg { path: "M3 21.5h15" }
        }
    }

    Repeater {
        model: 3

        Shape {
            id: wisp
            required property int index

            readonly property real baseX: (6.75 + index * 3.25) * cup.u
            width: 3 * cup.u
            height: 7 * cup.u
            x: baseX - 1.5 * cup.u
            y: 2 * cup.u + rise
            opacity: 0
            visible: cup.steaming
            preferredRendererType: Shape.CurveRenderer

            property real rise: 0

            ShapePath {
                strokeColor: cup.color
                strokeWidth: cup.stroke * cup.u * 0.85
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                scale: Qt.size(cup.u, cup.u)
                PathSvg { path: "M1.5 7C0.2 5.6 2.8 4.6 1.5 3.2S1.9 1 1.5 0" }
            }

            SequentialAnimation {
                running: cup.steaming && cup.visible
                loops: Animation.Infinite
                onStopped: { wisp.opacity = 0; wisp.rise = 0; }

                PauseAnimation { duration: wisp.index * 450 }
                SequentialAnimation {
                    loops: Animation.Infinite
                    ParallelAnimation {
                        NumberAnimation { target: wisp; property: "rise"; from: 1.5 * cup.u; to: -1.5 * cup.u; duration: 1400; easing.type: Easing.OutSine }
                        SequentialAnimation {
                            NumberAnimation { target: wisp; property: "opacity"; from: 0; to: 0.95; duration: 500; easing.type: Easing.OutQuad }
                            NumberAnimation { target: wisp; property: "opacity"; to: 0; duration: 900; easing.type: Easing.InQuad }
                        }
                    }
                    PauseAnimation { duration: 200 }
                }
            }
        }
    }
}
