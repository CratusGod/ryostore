import QtQuick
import Quickshell
import Quickshell.Wayland
import "face/obelisk" as ObeliskMod
import "face/tw" as TW

// Mandara — the Obelisk, seated as Ryoku's launcher.
//
// This envelope is her own window grammar from Jurai shell —
// a full-screen seat, the world dimmed to 0.45 behind her,
// click-away to retire, exclusive keys while she is up —
// wearing the one contract the shell's launcher host drives
// (shown / show(monitor) / hide() / toggle / stateDump), the
// same contract every Ryoku launcher keeps. Her face inside
// is the Obelisk herself, ported whole; what she answers is
// resolved locally by her own controller. No core, no court —
// the keystroke and the thing running, with her standing
// between them as she always did.
Scope {
    id: root

    // ── the contract the shell's launcher host drives ───────────────
    property bool openRequested: false
    readonly property bool shown: root.openRequested
    property string monitor: ""

    function show(mon) {
        root.monitor = mon || "";
        root.openRequested = true;
    }
    function hide() {
        root.openRequested = false;
    }
    function toggle(mon) {
        root.openRequested ? root.hide() : root.show(mon);
    }
    function stateDump() {
        return { open: root.openRequested, variant: "mandara" };
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

    // ── Rashin — the compass window (his word, 2026-10-25) ──
    // Natural language recognized by her lens is redirected
    // here: Mandara retires, Rashin opens with the line as
    // its seed. The window is the local mind's main window —
    // it outlives her summons, as a window should.
    Rashin {
        id: rashinWin
    }

    Connections {
        target: TW.SiMOrchestrator
        function onRashinRequested(seed) {
            root.hide();
            rashinWin.receive(seed);
        }
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

            // No dim — on his word (2026-10-25): when Mandara
            // is active the world stays as it is behind her.
            // Click-away still retires her.
            MouseArea {
                anchors.fill: parent
                onClicked: root.hide()
            }

            // Her entrance — a breath out of 0.98, quick,
            // with the overshoot her faces settle by.
            Item {
                id: stage
                anchors.fill: parent
                scale: 0.98
                opacity: 0
                Component.onCompleted: {
                    stage.scale = 1.0;
                    stage.opacity = 1.0;
                }
                Behavior on scale {
                    NumberAnimation { duration: 350; easing.type: Easing.OutBack; easing.overshoot: 1.2 }
                }
                Behavior on opacity {
                    NumberAnimation { duration: 250 }
                }

                ObeliskMod.Obelisk {
                    id: face
                    onCloseRequested: root.hide()
                    Component.onCompleted: {
                        face.focus = true;
                        face.openObelisk();
                    }
                }
            }
        }
    }
}
