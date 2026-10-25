pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Ryoku.Ui.Singletons
import "face/components" as Components
import "face/tw" as TW

FloatingWindow {
    id: win
    title: "Rashin"
    visible: false
    implicitWidth: 720
    implicitHeight: 560
    color: "transparent"

    property bool _opened: false
    signal dismissed()
    onVisibleChanged: if (!visible && _opened) {
        _opened = false
        if (win.busy)
            Spawn.run(["ryoku-rashin", "ask", "--cancel"])
        dismissed()
    }

    property string askedQuestion: ""
    property string working: ""
    property string answerText: ""
    property string errorText: ""
    property bool busy: false

    readonly property var messages: {
        var rows = []
        if (win.askedQuestion !== "")
            rows.push({ "who": "user", "text": win.askedQuestion })
        if (win.busy)
            rows.push({ "who": "rashin", "text": win.working || "Thinking…" })
        else if (win.errorText !== "")
            rows.push({ "who": "rashin", "text": win.errorText })
        else if (win.answerText !== "")
            rows.push({ "who": "rashin", "text": win.answerText })
        return rows
    }

    function ask(value) {
        var next = String(value || "").trim()
        if (next === "" || win.busy) return
        win.askedQuestion = next
        win.working = "Waking the needle"
        win.answerText = ""
        win.errorText = ""
        win.busy = true
        askProc.command = ["sh", "-c", "exec ryoku-rashin ask \"$1\"", "sh", next]
        askProc.running = true
    }

    Process {
        id: askProc
        environment: Spawn.env
        stdout: SplitParser {
            onRead: line => {
                var marker = String(line)
                if (marker.indexOf("@working ") === 0) {
                    win.working = marker.slice(9)
                } else if (marker.indexOf("@answer ") === 0) {
                    try {
                        const answer = JSON.parse(marker.slice(8))
                        win.answerText = String(answer.text || "")
                        win.busy = false
                        Qt.callLater(function() { _thread.positionViewAtEnd() })
                    } catch (error) {
                        win.errorText = "Unreadable answer"
                        win.busy = false
                    }
                } else if (marker.indexOf("@error ") === 0) {
                    win.errorText = marker.slice(7)
                    win.busy = false
                }
            }
        }
        onExited: code => {
            if (!win.busy) return
            win.errorText = code === 127
                ? "Rashin is off. Switch it on in Ryoku Hub."
                : code === 0 ? "No answer" : "Ask failed"
            win.busy = false
        }
    }

    function receive(seed) {
        win._opened = true
        win.visible = true
        Qt.callLater(function() { _input.forceActiveFocus() })
        win.ask(seed)
    }

    function _send() {
        var t = _input.text.trim()
        if (t.length === 0 || win.busy) return
        _input.text = ""
        win.ask(t)
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
                        text: "羅針 · THE COMPASS — RYOKU ASK"
                        font.pixelSize: 9
                        font.letterSpacing: 2
                        color: Qt.rgba(1, 1, 1, 0.38)
                    }
                }
                Item { Layout.fillWidth: true }
                Rectangle {
                    width: 6; height: 6; radius: 3
                    color: win.busy ? "#FFB300"
                        : win.errorText !== "" ? "#f43f5e" : "#10b981"
                    anchors.verticalCenter: parent.verticalCenter
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        running: win.busy
                        NumberAnimation { from: 1.0; to: 0.35; duration: 700 }
                        NumberAnimation { from: 0.35; to: 1.0; duration: 700 }
                    }
                }
                Text {
                    text: win.busy ? "RASHIN ASK · WORKING"
                        : win.errorText !== "" ? "RASHIN ASK · OFFLINE"
                        : "RASHIN ASK · READY"
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
                    text: "Ask a question, or press Escape to return."
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
                            textFormat: Text.PlainText
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
