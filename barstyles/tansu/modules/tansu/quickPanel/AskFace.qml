import QtQuick
import shell.services as Ryoku
import "../../../modules/common"
import "../../../modules/common/widgets"

// Rashin as a phone screen: the transcript Needle keeps for the shell's Agent
// surfaces, in a message thread with the phone's own composer under it.
Item {
    id: face

    readonly property bool classicPanel: true

    width: 654
    height: 1214

    property real renderScale: 1
    property bool active: false
    property bool registered: false

    // ready is the quick-ask lane's readiness; the agent lane answers even when
    // no quick provider resolves, so only the bridge being down blocks.
    readonly property bool blocked: !Ryoku.Needle.available
    readonly property int count: Ryoku.Needle.convo.count

    readonly property string statusText: {
        if (!Ryoku.Needle.available)
            return "Rashin is off · switch it on in Ryoku Hub"
        if (Ryoku.Needle.busy)
            return Ryoku.Needle.activity !== "" ? Ryoku.Needle.activity : "working"
        return Ryoku.Needle.currentModel !== "" ? Ryoku.Needle.currentModel : "ready"
    }

    function sendDraft() {
        const text = draft.text.trim()
        if (text.length === 0 || Ryoku.Needle.busy || blocked)
            return
        // The daemon hands a user message to every client but the one that
        // wrote it, so the phone puts its own line in the thread.
        if (Ryoku.Needle.available)
            Ryoku.Needle._frame(JSON.stringify({ type: "user", text: text }))
        Ryoku.Needle.send(text)
        draft.text = ""
    }

    function focusDraft() {
        draft.forceActiveFocus()
        draft.cursorPosition = draft.text.length
    }

    onActiveChanged: {
        if (active) {
            if (!registered) {
                Ryoku.Needle.agentSurfaceOpened()
                registered = true
            }
            Ryoku.Needle.noteOpened()
            Qt.callLater(chat.positionViewAtEnd)
            Qt.callLater(face.focusDraft)
        } else if (registered) {
            Ryoku.Needle.agentSurfaceClosed()
            registered = false
        }
    }

    Component.onDestruction: {
        if (registered)
            Ryoku.Needle.agentSurfaceClosed()
    }

    Connections {
        target: Ryoku.Needle
        enabled: face.active
        function onTouched() { chat.positionViewAtEnd() }
    }

    Text {
        x: 68
        y: 44
        text: "Rashin"
        color: Theme.pInk
        font.family: Theme.fontFamily
        font.pixelSize: 24
        font.weight: Font.ExtraBold
        font.styleName: Theme.fontStyleBold
    }

    Text {
        x: 68
        y: 78
        width: 420
        elide: Text.ElideRight
        text: face.statusText
        color: Theme.pInkSub
        font.family: Theme.fontFamily
        font.pixelSize: 18
    }

    SettingRoundButton {
        x: 512
        y: 34
        size: 44
        icon: "add-circle"
        onClicked: Ryoku.Needle.newChat()
    }

    Rectangle {
        id: card

        x: 36
        y: 122
        width: 582
        height: 800
        radius: 32
        color: Theme.pSurface
        border.width: 3
        border.color: Theme.pLine

        ListView {
            id: chat

            anchors.fill: parent
            anchors.margins: 18
            clip: true
            spacing: 10
            boundsBehavior: Flickable.StopAtBounds
            model: Ryoku.Needle.convo

            onCountChanged: Qt.callLater(chat.positionViewAtEnd)
            onContentHeightChanged: if (chat.atYEnd || chat.contentHeight < chat.height)
                Qt.callLater(chat.positionViewAtEnd)

            delegate: Column {
                id: row

                required property string kind
                required property string role
                required property string body
                required property string title
                required property string status

                width: chat.width
                spacing: 5

                Row {
                    visible: row.kind !== "msg"
                    spacing: 8

                    MaterialIcon {
                        anchors.verticalCenter: parent.verticalCenter
                        name: row.kind === "handoff" ? "transfer-horizontal" : "sledgehammer"
                        size: 20
                        color: Theme.pInkSub
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: row.kind === "handoff" ? "handed to chat"
                            : row.title + (row.status !== "" ? " · " + row.status : "")
                        color: Theme.pInkSub
                        font.family: Theme.fontFamily
                        font.pixelSize: 16
                    }
                }

                Text {
                    visible: row.kind === "msg" && row.role !== "user"
                    x: 17
                    text: "Rashin"
                    color: Theme.pInkSub
                    font.family: Theme.fontFamily
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    id: bubble

                    visible: row.kind === "msg"
                    x: row.role === "user" ? row.width - width : 0
                    width: Math.min(bodyText.implicitWidth, row.width * 0.78) + 34
                    height: bodyText.implicitHeight + 26
                    radius: 22
                    color: row.role === "user" ? Theme.surfaceTint : Theme.pSurfaceHover
                    border.width: 2
                    border.color: row.role === "user" ? Theme.accentCyan : Theme.pLine
                    antialiasing: true

                    Text {
                        id: bodyText

                        x: 17
                        y: 13
                        width: Math.min(implicitWidth, row.width * 0.78)
                        text: row.body
                        wrapMode: Text.Wrap
                        color: Theme.pInk
                        font.family: Theme.fontFamily
                        font.pixelSize: 19
                        lineHeight: 25
                        lineHeightMode: Text.FixedHeight
                    }
                }
            }
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - 90
            spacing: 14
            visible: chat.count === 0

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                text: face.blocked ? face.statusText
                    : Ryoku.Needle.busy ? face.statusText : "Ask Rashin anything"
                color: Theme.pInkSub
                font.family: Theme.fontFamily
                font.pixelSize: 19
            }

            Flow {
                width: parent.width
                visible: !face.blocked && !Ryoku.Needle.busy
                spacing: 8

                Repeater {
                    model: ["Summarise this desktop", "What is running?", "Tidy my downloads"]

                    delegate: Rectangle {
                        required property string modelData

                        width: chipText.implicitWidth + 30
                        height: 40
                        radius: 20
                        color: Theme.pSurfaceHover
                        border.width: 2
                        border.color: Theme.pLine

                        Text {
                            id: chipText
                            anchors.centerIn: parent
                            text: parent.modelData
                            color: Theme.pInk
                            font.family: Theme.fontFamily
                            font.pixelSize: 16
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                draft.text = parent.modelData
                                face.focusDraft()
                            }
                        }
                    }
                }
            }
        }

        // What the agent is doing, under the thread while it works.
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
            visible: chat.count > 0 && Ryoku.Needle.busy
            text: face.statusText
            color: Theme.pInkSub
            font.family: Theme.fontFamily
            font.pixelSize: 16
        }
    }

    Rectangle {
        id: field

        x: 52
        y: 950
        width: 550
        height: 80
        radius: 40
        color: Theme.pSurface
        border.width: 3
        border.color: draft.activeFocus ? Theme.accentCyan : Theme.pLine

        TextInput {
            id: draft

            x: 28
            width: parent.width - 110
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.pInk
            selectionColor: Theme.accentCyan
            selectedTextColor: Theme.pInk
            font.family: Theme.fontFamily
            font.pixelSize: 21
            clip: true
            selectByMouse: true
            // Stay typable while a turn runs: only a missing model disables it,
            // and a turn that took the field away lost the focus with it.
            enabled: !face.blocked

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                    face.sendDraft()
                } else {
                    return
                }
                event.accepted = true
            }
        }

        Text {
            x: 28
            anchors.verticalCenter: parent.verticalCenter
            visible: draft.text.length === 0
            text: face.blocked ? "Connect a model in Ryoku Hub"
                : Ryoku.Needle.busy ? "Rashin is working" : "Message Rashin"
            color: Theme.pInkSub
            font.family: Theme.fontFamily
            font.pixelSize: 21
        }

        SettingRoundButton {
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            size: 58
            icon: Ryoku.Needle.busy ? "stop" : "arrow-up"
            on: Ryoku.Needle.busy
            onClicked: Ryoku.Needle.busy ? Ryoku.Needle.cancel() : face.sendDraft()
        }
    }

    Text {
        x: 60
        y: 1046
        width: 534
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        visible: face.blocked
        text: face.statusText
        color: Theme.pInkSub
        font.family: Theme.fontFamily
        font.pixelSize: 16
    }
}
