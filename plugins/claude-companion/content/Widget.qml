pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.PluginKit.Singletons

// content/Widget.qml: the desktop companion. The spark sits on the wallpaper
// layer; a click opens the Claude panel under it (the tile grows in place, so
// there is no second window to steal focus). The host moves/resizes the tile and
// persists its position per monitor. Until Claude Code is installed and signed
// in, the panel shows the first-run setup instead of the chat.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "compact"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property string animState: service ? service.animState : "IDLE"
    readonly property bool open: service ? service.chatOpen : false
    readonly property int px: service ? service.pixelScale : 3
    readonly property string setup: service ? service.setup : "checking"

    // the host grabs the keyboard layer only while a text field holds focus
    readonly property bool editing: open && (input.activeFocus || codeInput.activeFocus)

    readonly property real panelW: 300
    readonly property real panelH: 250
    readonly property real gap: 6

    implicitWidth: Math.max(sprite.implicitWidth, open ? panelW : 0)
    implicitHeight: sprite.implicitHeight + (open ? gap + panelH : 0)

    readonly property var labels: ({
        IDLE: "Idle", SLEEPING: "Sleeping", AWAKE: "Waking up", THINKING: "Thinking",
        WORKING: "Working", LISTENING: "Waiting for you", SUCCESS: "Done", ERROR: "Error",
        ALERT: "Needs attention"
    })
    readonly property color dot: {
        if (setup !== "ready" && setup !== "checking") return Theme.gold;
        switch (animState) {
        case "THINKING": return Theme.gold;
        case "WORKING": return Theme.accent;
        case "SUCCESS": return "#7fd19a";
        case "ERROR": case "ALERT": return "#e5594a";
        case "LISTENING": return Theme.moonGlow;
        default: return Theme.dim;
        }
    }
    readonly property string headLabel: setup === "ready" || setup === "checking"
        ? (labels[animState] || animState) : "Setup"

    // small text button used by the setup views
    component PillButton: Rectangle {
        id: btn
        property string label: ""
        property bool primary: false
        signal clicked()
        implicitWidth: lbl.implicitWidth + 20
        implicitHeight: 26
        color: primary ? (hit.containsMouse ? Theme.accent : "transparent") : "transparent"
        border.color: hit.containsMouse || primary ? Theme.accent : Theme.border
        border.width: 1
        Text {
            id: lbl
            anchors.centerIn: parent
            text: btn.label
            color: btn.primary && hit.containsMouse ? Theme.cardTop : (hit.containsMouse || btn.primary ? Theme.accent : Theme.dim)
            font.family: Theme.mono
            font.pixelSize: 11
        }
        MouseArea { id: hit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: btn.clicked() }
    }

    Item {
        id: spriteBox
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        width: sprite.implicitWidth
        height: sprite.implicitHeight

        PixelSprite {
            id: sprite
            pixelScale: root.px
            season: root.service ? root.service.seasonNow : ""
            anim: root.animState.toLowerCase()
            animate: root.active !== false && !(root.service && root.service.reducedMotion)
        }

        SeasonFx {
            anchors.fill: sprite
            season: root.service ? root.service.seasonNow : ""
            pixelScale: root.px
            animate: root.active !== false && !(root.service && root.service.reducedMotion)
        }

        // debug overlay: state, animation, frame, fps, bridge status
        Rectangle {
            visible: !!root.service && root.service.debugOverlay
            anchors.left: parent.right
            anchors.leftMargin: 4
            anchors.top: parent.top
            width: dbg.implicitWidth + 10
            height: dbg.implicitHeight + 8
            color: Qt.rgba(0, 0, 0, 0.72)
            Text {
                id: dbg
                anchors.centerIn: parent
                color: "#e8e8e8"
                font.family: Theme.mono
                font.pixelSize: 10
                lineHeight: 1.15
                text: !root.service ? "" :
                    "state     " + root.animState + "\n" +
                    "claude    " + root.service.claudeState + (root.service.tool ? " (" + root.service.tool + ")" : "") + "\n" +
                    "anim      " + sprite.anim + "\n" +
                    "frame     " + (sprite.step + 1) + "/" + sprite.count + "\n" +
                    "fps       " + sprite.fps + (sprite.animate ? "" : " (static)") + "\n" +
                    "season    " + (root.service.seasonNow || "none") + "\n" +
                    "setup     " + root.service.setup + "\n" +
                    "bridge    " + (root.service.connected ? "CONNECTED" : "DISCONNECTED") +
                    "  sessions " + root.service.sessions
            }
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if (!root.service) return;
                root.service.poke();
                root.service.chatOpen = !root.service.chatOpen;
                if (root.service.chatOpen && root.setup === "ready") input.forceActiveFocus();
            }
        }
    }

    // ── Claude panel ───────────────────────────────────────────────────────────
    Rectangle {
        id: panel
        visible: root.open
        anchors.top: spriteBox.bottom
        anchors.topMargin: root.gap
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.panelW
        height: root.panelH
        color: Theme.cardTop
        border.color: Theme.border
        border.width: 1

        Keys.onEscapePressed: { if (root.service) root.service.chatOpen = false; }

        Row {
            id: head
            x: 12
            y: 10
            spacing: 8
            Rectangle { width: 8; height: 8; y: 4; color: root.dot }
            Text {
                text: "Claude  ·  " + root.headLabel
                color: Theme.bright
                font.family: Theme.mono
                font.pixelSize: 11
                font.weight: Font.DemiBold
            }
        }
        // new conversation / close
        Row {
            anchors.right: parent.right
            anchors.rightMargin: 12
            y: 9
            spacing: 12
            Text {
                visible: root.setup === "ready"
                text: "new"
                color: newHit.containsMouse ? Theme.accent : Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
                MouseArea { id: newHit; anchors.fill: parent; hoverEnabled: true; onClicked: root.service.reset() }
            }
            Text {
                text: "✕"
                color: closeHit.containsMouse ? Theme.accent : Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
                MouseArea { id: closeHit; anchors.fill: parent; hoverEnabled: true; onClicked: root.service.chatOpen = false }
            }
        }
        Rectangle { x: 12; y: 30; width: parent.width - 24; height: 1; color: Theme.hair }

        // ── first-run setup ────────────────────────────────────────────────────
        Item {
            id: setupView
            visible: root.setup !== "ready"
            x: 12
            y: 38
            width: parent.width - 24
            height: parent.height - 38 - 12

            readonly property string guideUrl: "https://code.claude.com/docs/en/setup"

            // the setup text can be taller than the panel on small scales: scroll it
            Flickable {
                id: setupFlick
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: setupCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

            Column {
                id: setupCol
                width: setupFlick.width
                spacing: 8

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.bright
                    font.family: Theme.font
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                    text: root.setup === "checking" ? "Checking Claude Code…"
                        : root.setup === "noCli" ? "Claude Code is not installed"
                        : root.setup === "noJq" ? "One helper tool is missing"
                        : root.setup === "signingIn" ? "Finish signing in with your browser"
                        : "Sign in to Claude"
                }

                Text {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 11
                    text: root.setup === "noCli"
                        ? "Claude Companion talks to Claude through the official Claude Code CLI. Follow the install guide for your system (a one-line installer or your package manager), then check again."
                        : root.setup === "noJq"
                        ? "Install `jq` with your package manager (for example pacman -S jq, apt install jq or dnf install jq), then check again."
                        : root.setup === "signingIn"
                        ? "A browser window should have opened. If it did not, open the link. If the page shows a code, paste it below."
                        : root.setup === "signedOut"
                        ? "Sign in once with your Claude account (Pro, Max, Team or Enterprise) or an Anthropic Console account. The sign-in is handled by Claude Code itself; this widget never sees your password or token."
                        : ""
                    visible: text.length > 0
                }

                // install guide address (selectable)
                Rectangle {
                    visible: root.setup === "noCli"
                    width: parent.width
                    height: 28
                    color: "transparent"
                    border.color: Theme.border
                    TextInput {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        readOnly: true
                        selectByMouse: true
                        text: setupView.guideUrl
                        color: Theme.bright
                        font.family: Theme.mono
                        font.pixelSize: 10
                        clip: true
                    }
                }

                // sign-in link (selectable) + code
                Rectangle {
                    visible: root.setup === "signingIn" && !!root.service && root.service.loginUrl.length > 0
                    width: parent.width
                    height: 26
                    color: "transparent"
                    border.color: Theme.border
                    TextInput {
                        id: urlField
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        readOnly: true
                        selectByMouse: true
                        text: root.service ? root.service.loginUrl : ""
                        onTextChanged: cursorPosition = 0
                        color: Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 10
                        clip: true
                    }
                }
                Rectangle {
                    visible: root.setup === "signingIn"
                    width: parent.width
                    height: 28
                    color: "transparent"
                    border.color: codeInput.activeFocus ? Theme.accent : Theme.border
                    TextInput {
                        id: codeInput
                        anchors.left: parent.left
                        anchors.right: codeBtn.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        color: Theme.bright
                        selectionColor: Theme.accent
                        font.family: Theme.mono
                        font.pixelSize: 10
                        clip: true
                        onAccepted: codeBtn.submit()
                        Keys.onEscapePressed: root.service.chatOpen = false
                        Text {
                            visible: codeInput.text.length === 0
                            anchors.verticalCenter: parent.verticalCenter
                            text: "paste the code here (if shown)"
                            color: Theme.dim
                            font: codeInput.font
                        }
                    }
                    Text {
                        id: codeBtn
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "send"
                        color: codeHit.containsMouse ? Theme.accent : Theme.dim
                        font.family: Theme.mono
                        font.pixelSize: 11
                        function submit() {
                            if (!root.service) return;
                            root.service.submitCode(codeInput.text);
                            codeInput.text = "";
                        }
                        MouseArea { id: codeHit; anchors.fill: parent; anchors.margins: -4; hoverEnabled: true; onClicked: codeBtn.submit() }
                    }
                }

                Text {
                    visible: !!root.service && root.service.loginNote.length > 0 && root.setup !== "noCli" && root.setup !== "noJq"
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: "#e5594a"
                    font.family: Theme.font
                    font.pixelSize: 11
                    text: root.service ? root.service.loginNote : ""
                }

                Row {
                    spacing: 8
                    PillButton {
                        visible: root.setup === "signedOut"
                        primary: true
                        label: "Sign in"
                        onClicked: root.service.login()
                    }
                    PillButton {
                        visible: root.setup === "signingIn" && !!root.service && root.service.loginUrl.length > 0
                        primary: true
                        label: "Open link"
                        onClicked: Qt.openUrlExternally(root.service.loginUrl)
                    }
                    PillButton {
                        visible: root.setup === "signingIn" && !!root.service && root.service.loginUrl.length > 0
                        label: "Copy link"
                        onClicked: { urlField.selectAll(); urlField.copy(); urlField.deselect(); }
                    }
                    PillButton {
                        visible: root.setup === "signingIn"
                        label: "Cancel"
                        onClicked: root.service.cancelLogin()
                    }
                    PillButton {
                        visible: root.setup === "noCli"
                        primary: true
                        label: "Install guide"
                        onClicked: Qt.openUrlExternally(setupView.guideUrl)
                    }
                    PillButton {
                        visible: root.setup === "noCli" || root.setup === "noJq" || root.setup === "signedOut"
                        label: "Check again"
                        onClicked: root.service.recheck()
                    }
                }
            }
            }
        }

        // ── chat ───────────────────────────────────────────────────────────────
        ListView {
            id: list
            visible: root.setup === "ready"
            x: 12
            y: 38
            width: parent.width - 24
            height: parent.height - 38 - 52
            clip: true
            spacing: 6
            model: root.service ? root.service.messages : null
            boundsBehavior: Flickable.StopAtBounds
            onCountChanged: positionViewAtEnd()
            onContentHeightChanged: if (atYEnd || root.service.chatBusy) positionViewAtEnd()

            delegate: Text {
                required property string role
                required property string body
                width: list.width
                wrapMode: Text.Wrap
                textFormat: Text.PlainText
                text: (role === "user" ? "› " : role === "tool" ? "⚙ " : role === "error" ? "! " : "") + body
                color: role === "user" ? Theme.accent
                     : role === "tool" ? Theme.dim
                     : role === "error" ? "#e5594a" : Theme.bright
                font.family: role === "tool" ? Theme.mono : Theme.font
                font.pixelSize: role === "tool" ? 10 : 12
                maximumLineCount: role === "tool" ? 1 : 200
                elide: role === "tool" ? Text.ElideRight : Text.ElideNone
            }

            Text {
                visible: list.count === 0
                anchors.fill: parent
                wrapMode: Text.Wrap
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 12
                text: !root.service ? "" : !root.service.bridgeEnabled
                    ? "Ask something below to start a chat."
                    : root.service.sessions > 0
                    ? "Watching " + root.service.sessions + " Claude Code session" + (root.service.sessions > 1 ? "s" : "") + ".\nAsk something below to start a chat."
                    : "No Claude Code session running.\nAsk something below to start a chat."
            }
        }

        Rectangle {
            visible: root.setup === "ready"
            x: 12
            y: parent.height - 44
            width: parent.width - 24
            height: 32
            color: "transparent"
            border.color: input.activeFocus ? Theme.accent : Theme.border
            border.width: 1

            TextInput {
                id: input
                objectName: "chatInput"
                anchors.left: parent.left
                anchors.right: sendBtn.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                color: Theme.bright
                selectionColor: Theme.accent
                font.family: Theme.font
                font.pixelSize: 12
                clip: true
                enabled: !!root.service && root.setup === "ready"
                onAccepted: root.submit()
                Keys.onEscapePressed: root.service.chatOpen = false
                Text {
                    visible: input.text.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.service && root.service.chatBusy ? "Claude is working…" : "Ask Claude…"
                    color: Theme.dim
                    font: input.font
                }
            }
            Text {
                id: sendBtn
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.service && root.service.chatBusy ? "stop" : "send"
                color: sendHit.containsMouse ? Theme.accent : Theme.dim
                font.family: Theme.mono
                font.pixelSize: 11
                MouseArea {
                    id: sendHit
                    anchors.fill: parent
                    anchors.margins: -4
                    hoverEnabled: true
                    onClicked: root.service.chatBusy ? root.service.cancel() : root.submit()
                }
            }
        }
    }

    function submit() {
        if (!service || service.chatBusy) return;
        const t = input.text;
        input.text = "";
        service.send(t);
    }
}
