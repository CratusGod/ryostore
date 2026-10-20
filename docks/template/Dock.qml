import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import Ryoku.Ui.Singletons
import shell.services
import shell.modules.stage.frame
import stage

// The smallest working Ryoku dock: your pinned apps, then the running ones, on
// the screen edge picked in Edit desktop -> Dock. Copy this folder, rename it
// and make it yours; docks/AUTHORING.md has the whole contract.
Item {
    id: root

    // ── the contract the shell's dock host drives ───────────────────────
    required property var screen
    property bool surfaceVisible: true
    property bool stageEditing: false

    // ── the settings every dock shares (Edit desktop -> Dock) ───────────
    readonly property string edge: Dock.resolvedEdge()
    readonly property bool horizontal: root.edge === "top" || root.edge === "bottom"
    readonly property real iconSize: Number(Dock.cfg("size", 44))
    readonly property bool autohide: Dock.cfg("autohide", true)
    // pinned apps first, then the running ones
    readonly property var pins: Dock.pinnedOrStarter()
    readonly property var apps: Dock.resolve(root.pins)

    readonly property string screenName: root.screen ? root.screen.name : ""
    readonly property real pad: 8
    readonly property real gap: 6
    readonly property real depth: root.iconSize + root.pad * 2
    readonly property bool revealed: root.stageEditing || !root.autohide || !Dock.anyFocused
        || plateHover.hovered || peekHover.hovered
        || (Dock.menuOpen && Dock.menuScreen === root.screenName)

    width: 0
    height: 0

    // The edge this dock holds while the Stage Editor frames its monitor, so
    // the editor's desktop icons keep clear of it.
    function publishInset() {
        GlobalStates.setDockInset(root.screenName, root.stageEditing ? root.edge : "", root.depth + root.gap);
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
        WlrLayershell.namespace: "ryoku-dock-template"
        // Above the lifted desktop while the Stage Editor shows it.
        WlrLayershell.layer: root.stageEditing ? WlrLayer.Overlay : WlrLayer.Top
        exclusionMode: ExclusionMode.Normal
        // A dock that stays put keeps windows clear of it; one that hides floats.
        exclusiveZone: root.autohide ? 0 : root.depth + root.gap
        anchors {
            left: root.horizontal || root.edge === "left"
            right: root.horizontal || root.edge === "right"
            top: !root.horizontal || root.edge === "top"
            bottom: !root.horizontal || root.edge === "bottom"
        }
        implicitHeight: root.horizontal ? frame.extent : 0
        implicitWidth: root.horizontal ? 0 : frame.extent

        // Only the plate and the peek strip take input; the rest of the strip
        // stays click-through.
        readonly property rect plateRect: frame.maskRect(plate.x, plate.y, plate.width, plate.height)
        readonly property rect peekRect: frame.maskRect(peek.x, peek.y, peek.width, peek.height)
        mask: Region {
            Region {
                x: Math.round(window.plateRect.x)
                y: Math.round(window.plateRect.y)
                width: Math.round(window.plateRect.width)
                height: Math.round(window.plateRect.height)
            }
            Region {
                x: Math.round(window.peekRect.x)
                y: Math.round(window.peekRect.y)
                width: Math.round(window.peekRect.width)
                height: Math.round(window.peekRect.height)
            }
        }

        // Draws the dock with the desktop when the Stage Editor shrinks this
        // monitor into its card.
        StageFramedLayer {
            id: frame
            screenName: root.screenName
            edge: root.edge
            restThickness: root.depth + root.gap
            screenWidth: root.screen?.width ?? 1920
            screenHeight: root.screen?.height ?? 1080
            originX: window.anchors.left ? 0 : screenWidth - window.width
            originY: window.anchors.top ? 0 : screenHeight - window.height

            Rectangle {
                id: plate

                // Slides off the edge when hidden, leaving the peek strip.
                readonly property real away: root.revealed ? 0 : root.depth + root.gap
                width: root.horizontal ? row.implicitWidth + root.pad * 2 : root.depth
                height: root.horizontal ? root.depth : row.implicitHeight + root.pad * 2
                x: root.horizontal ? Math.round((parent.width - width) / 2)
                    : root.edge === "left" ? root.gap - away : parent.width - width - root.gap + away
                y: !root.horizontal ? Math.round((parent.height - height) / 2)
                    : root.edge === "top" ? root.gap - away : parent.height - height - root.gap + away
                radius: Tokens.radius
                color: Tokens.paperLift
                border.width: Tokens.border
                border.color: Tokens.line

                Behavior on x { NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }
                Behavior on y { NumberAnimation { duration: Tokens.move; easing.type: Tokens.ease } }

                HoverHandler { id: plateHover }

                Grid {
                    id: row
                    anchors.centerIn: parent
                    columns: root.horizontal ? Math.max(1, root.apps.length) : 1
                    spacing: 4

                    Repeater {
                        model: root.apps

                        delegate: Item {
                            id: app
                            required property string modelData
                            readonly property int count: Dock.countFor(app.modelData)
                            readonly property bool pinned: root.pins.includes(app.modelData)

                            width: root.iconSize
                            height: root.iconSize

                            IconImage {
                                anchors.fill: parent
                                anchors.margins: 4
                                source: Dock.iconFor(app.modelData) || Icons.path("application-x-executable")
                            }

                            // running: a dot on the side facing the screen edge,
                            // in the accent for the focused app
                            Rectangle {
                                visible: app.count > 0
                                width: 4
                                height: 4
                                radius: 2
                                color: Dock.activeClass === app.modelData ? Tokens.sun : Tokens.ink
                                x: root.horizontal ? (parent.width - width) / 2
                                    : root.edge === "left" ? -6 : parent.width + 2
                                y: !root.horizontal ? (parent.height - height) / 2
                                    : root.edge === "top" ? -6 : parent.height + 2
                            }

                            HoverHandler { cursorShape: Qt.PointingHandCursor }

                            TapHandler {
                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                onSingleTapped: (point, button) => {
                                    if (button === Qt.RightButton) {
                                        const at = app.mapToGlobal(app.width / 2, app.height / 2);
                                        Dock.openMenu(app.modelData, app.pinned, app.count, at.x, at.y,
                                            root.screenName, root.edge, root.depth + root.gap);
                                    } else if (button === Qt.MiddleButton) {
                                        const entry = DesktopEntries.heuristicLookup(app.modelData);
                                        if (entry)
                                            AppLaunch.run(entry, null);
                                    } else {
                                        Dock.activate(app.modelData);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // A thin strip at the very edge that brings a hidden dock back.
            Item {
                id: peek
                x: root.horizontal ? plate.x : root.edge === "left" ? 0 : parent.width - root.gap
                y: !root.horizontal ? plate.y : root.edge === "top" ? 0 : parent.height - root.gap
                width: root.horizontal ? plate.width : root.gap
                height: root.horizontal ? root.gap : plate.height
                HoverHandler { id: peekHover }
            }
        }
    }
}
