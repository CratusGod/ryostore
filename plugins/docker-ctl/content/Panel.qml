pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// The panel: the daemon (start/stop, start at boot) on top, then every
// container with start/stop and restart. Click a container's name to edit its
// published ports and mounts; APPLY recreates it with them.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 420
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool up: service ? service.daemon === "active" : false
    readonly property bool busy: service ? service.busy : false

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    onActiveChanged: if (active && service) service.refresh()

    // ---- small parts -------------------------------------------------------

    component Btn: Rectangle {
        id: btn
        property string label: ""
        property bool primary: false
        property bool danger: false
        property bool enabledState: true
        // While true the label gives way to a spinning ring; the button keeps
        // its width so the row does not jump.
        property bool loading: false
        readonly property color ink: primary ? Theme.cardBot : (danger ? Theme.sun : Theme.bright)
        signal clicked()
        width: btnText.implicitWidth + 16 * root.s
        height: btnText.implicitHeight + 8 * root.s
        radius: Theme.radius
        opacity: enabledState || loading ? 1 : 0.45
        color: primary ? (btnArea.pressed ? Theme.vermDeep : Theme.accent)
                       : (btnArea.pressed ? Theme.hair : (btnArea.containsMouse ? Theme.sheen : Theme.tileBg))
        border.color: primary ? "transparent" : (danger ? Theme.sun : Theme.border)
        border.width: 1
        Text {
            id: btnText
            anchors.centerIn: parent
            opacity: btn.loading ? 0 : 1
            text: btn.label
            color: btn.ink
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }
        Canvas {
            id: spinner
            anchors.centerIn: parent
            width: 11 * root.s
            height: width
            visible: btn.loading
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.lineWidth = 1.6 * root.s;
                ctx.lineCap = "round";
                ctx.strokeStyle = btn.ink;
                ctx.beginPath();
                ctx.arc(width / 2, height / 2, width / 2 - ctx.lineWidth, 0, Math.PI * 1.5);
                ctx.stroke();
            }
            RotationAnimator on rotation {
                running: btn.loading
                from: 0
                to: 360
                duration: 800
                loops: Animation.Infinite
            }
        }
        MouseArea {
            id: btnArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: btn.enabledState
            cursorShape: Qt.PointingHandCursor
            onClicked: btn.clicked()
        }
    }

    component Field: Rectangle {
        id: fld
        property alias text: input.text
        property string placeholder: ""
        signal edited(string value)
        height: input.implicitHeight + 8 * root.s
        radius: Theme.radius
        color: Theme.cardBot
        border.color: input.activeFocus ? Theme.accent : Theme.border
        border.width: 1
        clip: true
        TextInput {
            id: input
            anchors.fill: parent
            anchors.leftMargin: 6 * root.s
            anchors.rightMargin: 6 * root.s
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.bright
            selectionColor: Theme.accent
            selectedTextColor: Theme.cardBot
            selectByMouse: true
            font.family: Theme.mono
            font.pixelSize: 11 * root.s
            onTextEdited: fld.edited(text)
            // Show a long path from its start, not scrolled to the end.
            onTextChanged: if (!activeFocus) cursorPosition = 0
        }
        Text {
            anchors.fill: input
            verticalAlignment: Text.AlignVCenter
            visible: input.text === "" && !input.activeFocus
            text: fld.placeholder
            color: Theme.faint
            opacity: 0.6
            font: input.font
            elide: Text.ElideRight
        }
    }

    component Caption: Text {
        color: Theme.dim
        font.family: Theme.font
        font.pixelSize: 11 * root.s
    }

    // ---- the editor's working copy -----------------------------------------

    ListModel { id: portsModel }
    ListModel { id: mountsModel }

    Connections {
        target: root.service
        function onEditingChanged() {
            portsModel.clear();
            mountsModel.clear();
            const e = root.service ? root.service.editing : null;
            if (!e) return;
            for (const p of e.ports)
                portsModel.append({ container: p.container, hostIp: p.hostIp, hostPort: p.hostPort });
            for (const m of e.mounts)
                mountsModel.append({ source: m.source || "", target: m.target, readOnly: m.readOnly });
        }
    }

    function specFromModels() {
        const ports = [], mounts = [];
        for (let i = 0; i < portsModel.count; i++) {
            const p = portsModel.get(i);
            ports.push({ container: p.container, hostIp: p.hostIp, hostPort: p.hostPort });
        }
        for (let i = 0; i < mountsModel.count; i++) {
            const m = mountsModel.get(i);
            mounts.push({ source: m.source, target: m.target, readOnly: m.readOnly });
        }
        return { ports: ports, mounts: mounts };
    }

    // ---- layout --------------------------------------------------------------

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 10 * root.s

        // Header: the daemon.
        Item {
            width: parent.width
            height: Math.max(head.implicitHeight, daemonBtns.height)

            Row {
                id: head
                spacing: 10 * root.s
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: ""
                    color: root.up ? Theme.accent : Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 22 * root.s
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "Docker"
                        color: Theme.bright
                        font.family: Theme.display
                        font.pixelSize: 16 * root.s
                    }
                    Caption {
                        text: !root.service ? ""
                            : (root.up ? root.service.runningCount + " running" : "Daemon " + root.service.daemon)
                              + " · " + (root.service.bootEnabled ? "starts at boot" : "off at boot")
                    }
                }
            }

            Row {
                id: daemonBtns
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6 * root.s
                Btn {
                    label: root.service && root.service.bootEnabled ? "BOOT: ON" : "BOOT: OFF"
                    enabledState: !root.busy
                    onClicked: root.service.setBoot(!root.service.bootEnabled)
                }
                Btn {
                    label: root.up ? "STOP" : "START"
                    loading: root.busy && root.service.busyAction === "daemon-" + (root.up ? "stop" : "start")
                    primary: !root.up
                    danger: root.up
                    enabledState: !root.busy
                    onClicked: root.up ? root.service.daemonStop() : root.service.daemonStart()
                }
            }
        }

        Text {
            width: parent.width
            visible: root.service && (root.service.error !== "" || root.service.notice !== "")
            wrapMode: Text.WordWrap
            text: root.service ? (root.service.error !== "" ? root.service.error : root.service.notice) : ""
            color: root.service && root.service.error !== "" ? Theme.sun : Theme.gold
            font.family: Theme.font
            font.pixelSize: 11 * root.s
        }

        // One-time setup: after this the daemon buttons never ask again.
        Rectangle {
            visible: root.service && !root.service.passwordless
            width: parent.width
            height: setupRow.implicitHeight + 12 * root.s
            radius: Theme.radius
            color: Theme.threadBg
            border.color: Theme.border
            border.width: 1
            Item {
                id: setupRow
                x: 8 * root.s
                y: 6 * root.s
                width: parent.width - 16 * root.s
                implicitHeight: Math.max(setupText.implicitHeight, setupBtn.height)
                Caption {
                    id: setupText
                    anchors.left: parent.left
                    anchors.right: setupBtn.left
                    anchors.rightMargin: 8 * root.s
                    anchors.verticalCenter: parent.verticalCenter
                    wrapMode: Text.WordWrap
                    text: "Starting and stopping Docker asks for your password. Allow it once and it never asks again."
                }
                Btn {
                    id: setupBtn
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    label: "ALLOW"
                    primary: true
                    enabledState: !root.busy
                    loading: root.busy && root.service.busyAction === "setup"
                    onClicked: root.service.setupPasswordless()
                }
            }
        }

        Rectangle { width: parent.width; height: 1; color: Theme.hair }

        Caption {
            visible: !root.up
            width: parent.width
            wrapMode: Text.WordWrap
            text: "The Docker daemon is not running."
        }
        Caption {
            visible: root.up && root.service && root.service.shown.length === 0
            text: "No containers."
        }

        // Containers.
        Flickable {
            id: flick
            visible: root.up
            width: parent.width
            height: Math.min(list.implicitHeight, 460 * root.s)
            contentHeight: list.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: list
                width: flick.width
                spacing: 4 * root.s

                Repeater {
                    model: root.service ? root.service.shown : []

                    delegate: Rectangle {
                        id: card
                        required property var modelData
                        readonly property bool running: modelData.state === "running"
                        readonly property bool editingThis: root.service && root.service.editingId === modelData.id
                        readonly property bool rowBusy: root.busy && root.service.busyId === modelData.id
                        width: list.width
                        height: cardCol.implicitHeight + 12 * root.s
                        radius: Theme.radius
                        color: editingThis ? Theme.tileBg : (rowArea.containsMouse ? Theme.sheen : "transparent")
                        border.color: editingThis ? Theme.border : "transparent"
                        border.width: 1

                        MouseArea { id: rowArea; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                        Column {
                            id: cardCol
                            x: 6 * root.s
                            y: 6 * root.s
                            width: parent.width - 12 * root.s
                            spacing: 8 * root.s

                            Item {
                                width: parent.width
                                height: Math.max(info.implicitHeight, actions.height)

                                Rectangle {
                                    id: dot
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 7 * root.s; height: width; radius: width / 2
                                    color: card.running ? Theme.accent
                                         : card.modelData.state === "restarting" ? Theme.gold : Theme.faint
                                }

                                Column {
                                    id: info
                                    anchors.left: dot.right
                                    anchors.leftMargin: 8 * root.s
                                    anchors.right: actions.left
                                    anchors.rightMargin: 8 * root.s
                                    anchors.verticalCenter: parent.verticalCenter
                                    Text {
                                        width: parent.width
                                        text: card.modelData.name
                                        color: nameArea.containsMouse ? Theme.accent : Theme.bright
                                        font.family: Theme.font
                                        font.pixelSize: 13 * root.s
                                        elide: Text.ElideRight
                                        MouseArea {
                                            id: nameArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            enabled: !root.busy
                                            onClicked: root.service.edit(card.modelData.id)
                                        }
                                    }
                                    Caption {
                                        width: parent.width
                                        elide: Text.ElideRight
                                        text: card.modelData.image + " · " + card.modelData.status
                                              + (card.modelData.ports.length ? " · " + card.modelData.ports.join(", ") : "")
                                    }
                                }

                                Row {
                                    id: actions
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4 * root.s
                                    Btn {
                                        label: card.running ? "STOP" : "START"
                                        loading: card.rowBusy && (root.service.busyAction === "stop" || root.service.busyAction === "start")
                                        enabledState: !root.busy
                                        onClicked: root.service.containerAction(card.running ? "stop" : "start", card.modelData.id)
                                    }
                                    Btn {
                                        label: "RESTART"
                                        loading: card.rowBusy && root.service.busyAction === "restart"
                                        enabledState: !root.busy && card.running
                                        onClicked: root.service.containerAction("restart", card.modelData.id)
                                    }
                                }
                            }

                            // ---- editor ----
                            Column {
                                visible: card.editingThis
                                width: parent.width
                                spacing: 6 * root.s

                                Caption {
                                    visible: card.editingThis && !root.service.editing
                                    text: "Reading the container…"
                                }

                                Column {
                                    visible: card.editingThis && !!root.service.editing
                                    width: parent.width
                                    spacing: 6 * root.s

                                    Caption { text: "PORTS   host port → container port/proto"; font.letterSpacing: 0.5 }
                                    Repeater {
                                        model: portsModel
                                        delegate: Row {
                                            id: prow
                                            required property int index
                                            required property string hostPort
                                            required property string container
                                            spacing: 4 * root.s
                                            Field {
                                                width: 80 * root.s
                                                text: prow.hostPort
                                                placeholder: "host"
                                                onEdited: v => portsModel.setProperty(prow.index, "hostPort", v)
                                            }
                                            Caption { anchors.verticalCenter: parent.verticalCenter; text: "→" }
                                            Field {
                                                width: 110 * root.s
                                                text: prow.container
                                                placeholder: "80/tcp"
                                                onEdited: v => portsModel.setProperty(prow.index, "container", v)
                                            }
                                            Btn { label: "✕"; onClicked: portsModel.remove(prow.index) }
                                        }
                                    }
                                    Btn {
                                        label: "+ PORT"
                                        onClicked: portsModel.append({ container: "", hostIp: "", hostPort: "" })
                                    }

                                    Caption { text: "MOUNTS   /host/path or volume → /container/path"; font.letterSpacing: 0.5 }
                                    Repeater {
                                        model: mountsModel
                                        delegate: Row {
                                            id: mrow
                                            required property int index
                                            required property string source
                                            required property string target
                                            required property bool readOnly
                                            readonly property real fieldW: (cardCol.width - 4 * 4 * root.s - 14 * root.s - roBtn.width - xBtn.width) / 2
                                            spacing: 4 * root.s
                                            Field {
                                                width: mrow.fieldW
                                                text: mrow.source
                                                placeholder: "/path or volume"
                                                onEdited: v => mountsModel.setProperty(mrow.index, "source", v)
                                            }
                                            Caption { anchors.verticalCenter: parent.verticalCenter; text: "→" }
                                            Field {
                                                width: mrow.fieldW
                                                text: mrow.target
                                                placeholder: "/data"
                                                onEdited: v => mountsModel.setProperty(mrow.index, "target", v)
                                            }
                                            Btn {
                                                id: roBtn
                                                label: mrow.readOnly ? "RO" : "RW"
                                                onClicked: mountsModel.setProperty(mrow.index, "readOnly", !mrow.readOnly)
                                            }
                                            Btn { id: xBtn; label: "✕"; onClicked: mountsModel.remove(mrow.index) }
                                        }
                                    }
                                    Btn {
                                        label: "+ MOUNT"
                                        onClicked: mountsModel.append({ source: "", target: "", readOnly: false })
                                    }

                                    Caption {
                                        width: parent.width
                                        wrapMode: Text.WordWrap
                                        color: Theme.gold
                                        text: "APPLY recreates the container (same image, env, networks; volumes kept)."
                                              + (root.service.editing && root.service.editing.compose
                                                 ? " It belongs to compose project “" + root.service.editing.compose
                                                   + "”: the next `docker compose up` puts its compose file's ports and mounts back."
                                                 : "")
                                    }

                                    Row {
                                        spacing: 6 * root.s
                                        Btn {
                                            label: "APPLY"
                                            loading: card.rowBusy && root.service.busyAction === "recreate"
                                            primary: true
                                            enabledState: !root.busy
                                            onClicked: root.service.apply(card.modelData.id, root.specFromModels())
                                        }
                                        Btn {
                                            label: "CANCEL"
                                            enabledState: !root.busy
                                            onClicked: root.service.closeEdit()
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
