import QtQuick
import Quickshell
import Quickshell.Wayland
import Ryoku.Ui.Singletons
import shell.services
import shell.modules.stage.frame
import stage

// Engawa: the dock as the veranda that runs along the edge of a house. One
// plank lies flush with the screen edge, every app on a board of its own, a nail
// for each open window and a vermilion nail for the window you are in.
Item {
    id: root

    // ── the dock host's contract ────────────────────────────────────────
    required property var screen
    property bool surfaceVisible: true
    property bool stageEditing: false

    // ── the settings every dock shares (Edit desktop -> Dock) ───────────
    readonly property string edge: Dock.resolvedEdge()
    readonly property bool horizontal: root.edge === "top" || root.edge === "bottom"
    readonly property real iconSize: Number(Dock.cfg("size", 44))
    readonly property bool autohide: Dock.cfg("autohide", true)
    readonly property bool magnify: Dock.cfg("magnify", true)
    readonly property var pins: Dock.pinnedOrStarter()
    readonly property var apps: Dock.resolve(root.pins)

    readonly property string screenName: root.screen ? root.screen.name : ""
    // The plank's thickness away from the edge, and the room beyond it that a
    // magnified icon and the name tag grow into (click-through).
    readonly property real depth: Math.round(root.iconSize + 26)
    readonly property real headroom: root.horizontal ? Math.round(root.iconSize * 0.3) + 40 : 196
    // What a hidden plank leaves on the edge: a hairline you can reach.
    readonly property real sliver: 3
    readonly property bool menuHere: Dock.menuOpen && Dock.menuScreen === root.screenName
    readonly property bool revealed: {
        if (root.stageEditing)
            return true;
        if (Wm.outputHasFullscreen(root.screenName))
            return plank.hovered || peekHover.hovered;
        return !root.autohide || !Dock.anyFocused || plank.hovered || peekHover.hovered || root.menuHere;
    }

    width: 0
    height: 0

    // The edge this dock holds while the Stage Editor frames its monitor, so
    // the editor's desktop icons keep clear of it.
    function publishInset() {
        GlobalStates.setDockInset(root.screenName, root.stageEditing ? root.edge : "", root.depth);
    }
    onStageEditingChanged: root.publishInset()
    onEdgeChanged: root.publishInset()
    onDepthChanged: root.publishInset()
    Component.onCompleted: root.publishInset()
    Component.onDestruction: GlobalStates.setDockInset(root.screenName, "", 0)

    PanelWindow {
        id: window

        screen: root.screen
        visible: root.surfaceVisible
        color: "transparent"
        WlrLayershell.namespace: "ryoku-dock-engawa"
        WlrLayershell.layer: root.stageEditing ? WlrLayer.Overlay : WlrLayer.Top
        exclusionMode: ExclusionMode.Normal
        exclusiveZone: root.autohide ? 0 : root.depth
        anchors {
            left: root.horizontal || root.edge === "left"
            right: root.horizontal || root.edge === "right"
            top: !root.horizontal || root.edge === "top"
            bottom: !root.horizontal || root.edge === "bottom"
        }
        implicitHeight: root.horizontal ? frame.extent : 0
        implicitWidth: root.horizontal ? 0 : frame.extent

        readonly property rect plankRect: frame.maskRect(plank.x, plank.y, plank.width, plank.height)
        readonly property rect peekRect: frame.maskRect(peek.x, peek.y, peek.width, peek.height)
        mask: Region {
            Region {
                x: Math.round(window.plankRect.x)
                y: Math.round(window.plankRect.y)
                width: Math.round(window.plankRect.width)
                height: Math.round(window.plankRect.height)
            }
            Region {
                x: Math.round(window.peekRect.x)
                y: Math.round(window.peekRect.y)
                width: Math.round(window.peekRect.width)
                height: Math.round(window.peekRect.height)
            }
        }

        StageFramedLayer {
            id: frame
            screenName: root.screenName
            edge: root.edge
            restThickness: root.depth + root.headroom
            screenWidth: root.screen?.width ?? 1920
            screenHeight: root.screen?.height ?? 1080
            originX: window.anchors.left ? 0 : screenWidth - window.width
            originY: window.anchors.top ? 0 : screenHeight - window.height

            Plank {
                id: plank

                edge: root.edge
                apps: root.apps
                pins: root.pins
                iconSize: root.iconSize
                depth: root.depth
                magnify: root.magnify
                screenName: root.screenName

                // Flush with the edge; hidden, it slides off and leaves its sliver.
                readonly property real away: root.revealed ? 0 : root.depth - root.sliver
                x: root.horizontal ? Math.round((parent.width - width) / 2)
                    : root.edge === "left" ? -away : parent.width - width + away
                y: !root.horizontal ? Math.round((parent.height - height) / 2)
                    : root.edge === "top" ? -away : parent.height - height + away
                Behavior on x { NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                Behavior on y { NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
            }

            NameTag {
                plank: plank
                edge: root.edge
            }

            // The strip at the very edge that brings a hidden plank back.
            Item {
                id: peek
                readonly property real reach: 6
                x: root.horizontal ? plank.x : root.edge === "left" ? 0 : parent.width - reach
                y: !root.horizontal ? plank.y : root.edge === "top" ? 0 : parent.height - reach
                width: root.horizontal ? plank.width : reach
                height: root.horizontal ? reach : plank.height
                HoverHandler { id: peekHover }
            }
        }
    }
}
