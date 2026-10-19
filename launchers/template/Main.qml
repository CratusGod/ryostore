import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets
import shell.services
import Ryoku.Ui.Singletons

// The smallest working Ryoku launcher: a search line over the apps that match.
// Copy this folder, rename it and make it yours; launchers/AUTHORING.md has the
// whole contract.
Scope {
    id: root

    // ── the contract the shell's launcher host drives ───────────────────
    property bool openRequested: false
    readonly property bool shown: root.openRequested
    property string monitor: ""

    function show(mon) {
        root.monitor = mon || "";
        root.query = "";
        root.selected = 0;
        root.openRequested = true;
    }
    function hide() {
        root.openRequested = false;
    }
    function toggle(mon) {
        root.openRequested ? root.hide() : root.show(mon);
    }
    function stateDump() {
        return { open: root.openRequested, query: root.query, resultCount: root.results.length };
    }

    // ── the launcher itself ─────────────────────────────────────────────
    property string query: ""
    property int selected: 0

    readonly property var results: {
        const q = root.query.trim().toLowerCase();
        return DesktopEntries.applications.values
            .filter(entry => !entry.noDisplay && entry.name.toLowerCase().includes(q))
            .sort((a, b) => a.name.localeCompare(b.name))
            .slice(0, 8);
    }

    // the output the host named, else the focused one
    readonly property var output: {
        const screens = Quickshell.screens;
        const wanted = root.monitor.length > 0 ? root.monitor : Wm.focusedOutput;
        for (let i = 0; i < screens.length; i++)
            if (screens[i].name === wanted)
                return screens[i];
        return screens.length > 0 ? screens[0] : null;
    }

    function launch(entry) {
        if (!entry)
            return;
        root.hide();
        AppLaunch.run(entry, null);
    }

    LazyLoader {
        active: root.shown && root.output !== null

        PanelWindow {
            screen: root.output
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "launcher"
            WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            Rectangle {
                width: Tokens.px(520)
                height: column.implicitHeight + Tokens.s4 * 2
                anchors.horizontalCenter: parent.horizontalCenter
                y: Math.round(parent.height * 0.22)
                radius: Tokens.radius
                color: Tokens.paperLift
                border.width: Tokens.border
                border.color: Tokens.lineStrong

                MouseArea {
                    anchors.fill: parent
                }

                Column {
                    id: column
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: Tokens.s4 }
                    spacing: Tokens.s2

                    TextInput {
                        id: field
                        width: parent.width
                        focus: true
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fValue
                        Component.onCompleted: field.forceActiveFocus()
                        onTextEdited: {
                            root.query = text;
                            root.selected = 0;
                        }
                        Keys.onEscapePressed: root.hide()
                        Keys.onReturnPressed: root.launch(root.results[root.selected])
                        Keys.onEnterPressed: root.launch(root.results[root.selected])
                        Keys.onDownPressed: root.selected = Math.min(root.results.length - 1, root.selected + 1)
                        Keys.onUpPressed: root.selected = Math.max(0, root.selected - 1)

                        Text {
                            visible: field.text.length === 0
                            text: I18n.tr("Search")
                            color: Tokens.inkFaint
                            font: field.font
                        }
                    }

                    Repeater {
                        model: root.results
                        delegate: Rectangle {
                            id: row
                            required property var modelData
                            required property int index
                            width: column.width
                            height: Tokens.rowH
                            radius: Tokens.radius
                            color: row.index === root.selected ? Tokens.tint10 : "transparent"

                            IconImage {
                                id: icon
                                anchors { left: parent.left; leftMargin: Tokens.s3; verticalCenter: parent.verticalCenter }
                                implicitSize: Tokens.px(24)
                                source: Icons.path(row.modelData.icon, "application-x-executable")
                            }
                            Text {
                                anchors { left: icon.right; leftMargin: Tokens.s3; verticalCenter: parent.verticalCenter }
                                text: row.modelData.name
                                color: Tokens.ink
                                font.family: Tokens.ui
                                font.pixelSize: Tokens.fRow
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.launch(row.modelData)
                            }
                        }
                    }
                }
            }
        }
    }
}
