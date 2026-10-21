import QtQuick
import QtQuick.Shapes

// A keyboard drawn from paths in a 24x16 box: an outlined body, two rows of
// keys and a space bar. `color` tints it; it scales to the item.
Item {
    id: root

    property color color: "white"
    property real stroke: 1.6

    readonly property real u: Math.min(width / 24, height / 16)

    implicitWidth: 24
    implicitHeight: 16

    Shape {
        width: 24 * root.u
        height: 16 * root.u
        anchors.centerIn: parent
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: root.color
            strokeWidth: root.stroke * root.u
            fillColor: "transparent"
            joinStyle: ShapePath.RoundJoin
            capStyle: ShapePath.RoundCap
            scale: Qt.size(root.u, root.u)
            PathSvg {
                path: "M3 1h18a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V3a2 2 0 0 1 2-2z"
                    + " M8 11.5h8"
            }
        }

        ShapePath {
            strokeColor: "transparent"
            fillColor: root.color
            scale: Qt.size(root.u, root.u)
            PathSvg {
                // Two rows of five keys, 2x2 each.
                path: "M4 4h2v2H4z M7.5 4h2v2h-2z M11 4h2v2h-2z M14.5 4h2v2h-2z M18 4h2v2h-2z"
                    + " M4 7.5h2v2H4z M7.5 7.5h2v2h-2z M11 7.5h2v2h-2z M14.5 7.5h2v2h-2z M18 7.5h2v2h-2z"
            }
        }
    }
}
