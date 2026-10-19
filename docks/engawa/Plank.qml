import QtQuick
import Ryoku.Ui.Singletons
import shell.services

// The plank: the maker's mark, then one board per app, pinned ones first, with
// a doubled seam where the apps that are only running begin. A beam runs along
// the side away from the screen edge.
Rectangle {
    id: root

    required property string edge
    required property var apps
    required property var pins
    required property real iconSize
    required property real depth
    required property bool magnify
    required property string screenName

    readonly property bool horizontal: root.edge === "top" || root.edge === "bottom"
    readonly property real boardLength: Math.round(root.iconSize + 18)
    readonly property real markLength: 28
    readonly property real tailLength: 8
    readonly property real length: root.markLength + root.apps.length * root.boardLength + root.tailLength
    readonly property bool hovered: hover.hovered
    // The board under the pointer, -1 for none: it lifts and magnifies, and the
    // name tag reads it.
    property int hoverIndex: -1
    readonly property string hoverName: {
        if (root.hoverIndex < 0 || root.hoverIndex >= root.apps.length)
            return "";
        const className = root.apps[root.hoverIndex];
        const entry = Dock.entryFor(className);
        return entry && entry.name ? entry.name : className;
    }

    width: root.horizontal ? root.length : root.depth
    height: root.horizontal ? root.depth : root.length
    color: Tokens.paperLift
    border.width: Tokens.border
    border.color: Tokens.lineSoft

    HoverHandler {
        id: hover
        onHoveredChanged: if (!hover.hovered) root.hoverIndex = -1
    }

    // the beam along the side away from the edge
    Rectangle {
        color: Tokens.lineStrong
        width: root.horizontal ? parent.width : Tokens.border
        height: root.horizontal ? Tokens.border : parent.height
        x: root.edge === "left" ? parent.width - width : 0
        y: root.edge === "top" ? parent.height - height : 0
    }

    // the maker's mark at the leading end
    Item {
        width: root.horizontal ? root.markLength : root.depth
        height: root.horizontal ? root.depth : root.markLength

        Text {
            anchors.centerIn: parent
            text: "縁"
            color: Tokens.inkFaint
            font.family: Tokens.jp
            font.pixelSize: 12
        }
    }

    Grid {
        x: root.horizontal ? root.markLength : 0
        y: root.horizontal ? 0 : root.markLength
        columns: root.horizontal ? Math.max(1, root.apps.length) : 1

        Repeater {
            model: root.apps

            delegate: Board {
                required property string modelData
                plank: root
                className: modelData
            }
        }
    }
}
