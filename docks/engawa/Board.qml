import QtQuick
import Quickshell
import Quickshell.Widgets
import Ryoku.Ui.Singletons
import shell.services

// One app on its board: the icon, a nail per open window (vermilion on the
// window you are in), and the seam it shares with the board before it.
Item {
    id: board

    required property var plank
    required property string className
    required property int index

    readonly property string edge: board.plank.edge
    readonly property bool horizontal: board.plank.horizontal
    readonly property int count: Dock.countFor(board.className)
    readonly property bool pinned: board.plank.pins.includes(board.className)
    readonly property bool focused: board.count > 0 && Dock.activeClass === board.className
    // The first app that is only running: a doubled seam sets it apart from
    // the pins before it.
    readonly property bool joint: !board.pinned && board.index > 0
        && board.plank.pins.includes(board.plank.apps[board.index - 1])
    readonly property bool hovered: hover.hovered
    readonly property real magnification: {
        if (!board.plank.magnify || board.plank.hoverIndex < 0)
            return 1;
        const distance = Math.abs(board.index - board.plank.hoverIndex);
        return distance === 0 ? 1.24 : distance === 1 ? 1.08 : 1;
    }
    // How far the icon rises away from the edge: a little on hover, more while
    // an app it launched is starting.
    property real lift: board.hovered ? 3 : 0
    property real hop: 0
    Behavior on lift { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.ease } }

    width: board.horizontal ? board.plank.boardLength : board.plank.depth
    height: board.horizontal ? board.plank.depth : board.plank.boardLength

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: board.focused ? Tokens.tint10 : board.hovered ? Tokens.tint5 : "transparent"
        Behavior on color { ColorAnimation { duration: Tokens.snap } }
    }

    // the seam on the leading side, doubled at the joint
    Repeater {
        model: board.joint ? 2 : 1

        Rectangle {
            required property int index
            color: board.joint ? Tokens.line : Tokens.lineSoft
            width: board.horizontal ? Tokens.border : board.width
            height: board.horizontal ? board.height : Tokens.border
            x: board.horizontal ? index * 3 : 0
            y: board.horizontal ? 0 : index * 3
        }
    }

    IconImage {
        id: icon

        // clear of the nails between the icon and the edge
        readonly property real nailRoom: 12
        implicitSize: board.plank.iconSize
        source: Dock.iconFor(board.className) || Icons.path("application-x-executable")
        x: board.horizontal ? Math.round((board.width - width) / 2)
            : board.edge === "left" ? nailRoom : board.width - width - nailRoom
        y: !board.horizontal ? Math.round((board.height - height) / 2)
            : board.edge === "top" ? nailRoom : board.height - height - nailRoom
        scale: board.magnification
        transformOrigin: board.edge === "bottom" ? Item.Bottom
            : board.edge === "top" ? Item.Top
            : board.edge === "left" ? Item.Left : Item.Right
        Behavior on scale { NumberAnimation { duration: Tokens.snap; easing.type: Tokens.ease } }
        transform: Translate {
            readonly property real rise: board.lift + board.hop
            x: board.horizontal ? 0 : board.edge === "left" ? rise : -rise
            y: !board.horizontal ? 0 : board.edge === "top" ? rise : -rise
        }
    }

    // a nail per open window, up to three, between the icon and the edge
    Grid {
        columns: board.horizontal ? 3 : 1
        spacing: 3
        x: board.horizontal ? Math.round((board.width - width) / 2)
            : board.edge === "left" ? 4 : board.width - width - 4
        y: !board.horizontal ? Math.round((board.height - height) / 2)
            : board.edge === "top" ? 4 : board.height - height - 4

        Repeater {
            model: Math.min(3, board.count)

            Rectangle {
                required property int index
                width: 4
                height: 4
                color: board.focused && index === 0 ? Tokens.sun : Tokens.ink
            }
        }
    }

    SequentialAnimation {
        id: hopAnimation
        NumberAnimation { target: board; property: "hop"; to: 9; duration: Tokens.dur(140); easing.type: Easing.OutQuad }
        NumberAnimation { target: board; property: "hop"; to: 0; duration: Tokens.dur(320); easing.type: Easing.OutBounce }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
        onHoveredChanged: {
            if (hover.hovered)
                board.plank.hoverIndex = board.index;
            else if (board.plank.hoverIndex === board.index)
                board.plank.hoverIndex = -1;
        }
    }

    TapHandler {
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onSingleTapped: (point, button) => {
            if (button === Qt.RightButton) {
                const at = board.mapToGlobal(board.width / 2, board.height / 2);
                Dock.openMenu(board.className, board.pinned, board.count, at.x, at.y,
                    board.plank.screenName, board.edge, board.plank.depth);
                return;
            }
            if (button === Qt.MiddleButton) {
                const entry = DesktopEntries.heuristicLookup(board.className);
                if (entry) {
                    AppLaunch.run(entry, null);
                    hopAnimation.restart();
                }
                return;
            }
            if (board.count === 0)
                hopAnimation.restart();
            Dock.activate(board.className);
        }
    }
}
