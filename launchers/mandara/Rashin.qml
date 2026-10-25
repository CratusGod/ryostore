/* Rashin.qml — 羅針, the compass window.
 *
 * The local mind's main window (his word, 2026-10-25): what
 * Insei was to the shell, Rashin is to the Ryoku house — a
 * window of her own, not a layer in someone else's. Mandara
 * recognizes natural language, redirects it here by signal,
 * and retires; this window receives the line as its seed.
 *
 * The mind behind the window is still being seated — she
 * answers with presence, honestly labelled resting, and
 * every word is kept in the house's own state file. Nothing
 * leaves the machine.
 */
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "face/components" as Components
import "face/tw" as TW

FloatingWindow {
    id: win
    title: "Rashin"
    visible: false
    implicitWidth: 720
    implicitHeight: 560
    color: "transparent"

    property var messages: []
    property bool _loaded: false
    property int _replyCount: 0

    readonly property var _restingReplies: [
        "Heard. This window is my seat now — the local mind behind it is still being seated, so today I answer with presence: your words are kept here, in this house, and nowhere else.",
        "Kept. When the mind wakes in this window, this thread is the first thing it will read.",
        "I am listening. Rashin is the compass — bring me what is not a command, and I will hold it with you."
    ]

    FileView {
        id: store
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/ryoku/rashin-chat.json"
        blockLoading: true
        atomicWrites: true
        printErrors: false
    }

    Component.onCompleted: {
        try {
            var raw = store.text()
            var parsed = raw && raw.length ? JSON.parse(raw) : []
            win.messages = (parsed instanceof Array) ? parsed : []
        } catch (e) {
            win.messages = []
        }
        win._loaded = true
    }

    function _persist() {
        if (!win._loaded) return
        store.setText(JSON.stringify(win.messages.slice(-100)))
    }

    function _say(who, text) {
        if (!text) return
        win.messages = win.messages.concat([{ "who": who, "text": text }])
        win._persist()
        Qt.callLater(function() { _thread.positionViewAtEnd() })
    }

    function _replySoon() { _replyTimer.restart() }

    Timer {
        id: _replyTimer
        interval: 700
        repeat: false
        onTriggered: {
            win._say("rashin", win._restingReplies[win._replyCount % win._restingReplies.length])
            win._replyCount++
        }
    }

    // The redirect lands here: Mandara retires, Rashin opens,
    // the line arrives as the first word spoken.
    function receive(seed) {
        win.visible = true
        Qt.callLater(function() { _input.forceActiveFocus() })
        var s = (seed || "").trim()
        if (s.length > 0) {
            win._say("user", s)
            win._replySoon()
        }
    }

    function _send() {
        var t = _input.text.trim()
        if (t.length === 0) return
        _input.text = ""
        win._say("user", t)
        win._replySoon()
    }

    Rectangle {
        anchors.fill: parent
        radius: 18
        color: Qt.rgba(0.02, 0.04, 0.07, 0.97)
        border.width: 1
        border.color: Qt.alpha(TW.SiMOrchestrator.prismaticColor, 0.3)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 12

            // ── Her head — the mark, her name, her state ─────
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Image {
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    width: 30; height: 30
                    source: "face/components/emblem.png"
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    mipmap: true
                }
                Column {
                    spacing: 1
                    Text {
                        text: "RASHIN"
                        font.family: Components.Typography.technical
                        font.weight: 700
                        font.pixelSize: 15
                        font.letterSpacing: 4
                        color: Qt.rgba(0.93, 0.95, 1.0, 0.95)
                    }
                    Text {
                        text: "羅針 · THE COMPASS — INSEI'S WINDOW"
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        color: Qt.rgba(1, 1, 1, 0.38)
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: "#FFB300"
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { from: 1.0; to: 0.35; duration: 1400 }
                        NumberAnimation { from: 0.35; to: 1.0; duration: 1400 }
                    }
                }
                Text {
                    text: "LOCAL MIND · RESTING"
                    font.pixelSize: 9
                    font.letterSpacing: 1.5
                    color: Qt.rgba(1, 1, 1, 0.38)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "✕"
                    font.pixelSize: 13
                    color: Qt.rgba(1, 1, 1, 0.45)
                    anchors.verticalCenter: parent.verticalCenter
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win.visible = false
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Qt.rgba(1, 1, 1, 0.06)
            }

            // ── The thread ───────────────────────────────────
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    anchors.centerIn: parent
                    width: parent.width - 80
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: "The compass is open.\nCommands belong to Mandara — questions belong here."
                    font.family: "Fira Code"
                    font.pixelSize: 13
                    font.italic: true
                    color: Qt.rgba(1, 1, 1, 0.30)
                    visible: win.messages.length === 0
                }

                ListView {
                    id: _thread
                    anchors.fill: parent
                    clip: true
                    spacing: 10
                    model: win.messages

                    delegate: Row {
                        required property var modelData
                        width: _thread.width
                        spacing: 10

                        Text {
                            text: modelData.who === "rashin" ? "羅" : "❯"
                            font.family: "Fira Code"
                            font.pixelSize: 13
                            font.bold: true
                            color: modelData.who === "rashin" ? "#FFB300" : Qt.rgba(1, 1, 1, 0.35)
                            width: 18
                        }
                        Text {
                            width: parent.width - 28
                            wrapMode: Text.WordWrap
                            text: modelData.text
                            font.family: "Fira Code"
                            font.pixelSize: 14
                            lineHeight: 1.25
                            color: modelData.who === "rashin"
                                ? Qt.rgba(0.78, 0.88, 1.0, 0.95)
                                : Qt.rgba(1, 1, 1, 0.92)
                        }
                    }
                }
            }

            // ── Her input — a quiet lens of her own ──────────
            Rectangle {
                Layout.fillWidth: true
                height: 44
                radius: 22
                color: Qt.rgba(1, 1, 1, 0.04)
                border.width: 1
                border.color: Qt.rgba(0.0, 0.76, 1.0, _input.activeFocus ? 0.50 : 0.20)
                Behavior on border.color { ColorAnimation { duration: 150 } }

                TextField {
                    id: _input
                    anchors.fill: parent
                    anchors.leftMargin: 16
                    anchors.rightMargin: 44
                    background: Item {}
                    font.family: "Fira Code"
                    font.pixelSize: 14
                    color: Qt.rgba(1, 1, 1, 0.92)
                    placeholderText: "speak to rashin…"
                    placeholderTextColor: Qt.rgba(1, 1, 1, 0.25)
                    verticalAlignment: TextInput.AlignVCenter
                    onAccepted: win._send()
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Escape) {
                            event.accepted = true
                            win.visible = false
                        }
                    }
                }
                Text {
                    anchors.right: parent.right
                    anchors.rightMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "羅"
                    font.pixelSize: 17
                    font.bold: true
                    color: _input.text.trim().length > 0 ? "#FFB300" : Qt.rgba(1, 1, 1, 0.25)
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -8
                        cursorShape: Qt.PointingHandCursor
                        onClicked: win._send()
                    }
                }
            }
        }
    }
}
