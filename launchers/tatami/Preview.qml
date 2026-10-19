import QtQuick
import Ryoku.Ui.Singletons

// Tatami in Ryoku Settings: a still of the sheet, the search line over the
// section index and one row of mats, the chosen one marked.
Item {
    id: root

    property var settings: ({})
    signal editRequested(string key, var value)

    implicitWidth: 720
    implicitHeight: 250

    readonly property var sections: [["ALL", "112"], ["INTERNET", "9"], ["MEDIA", "7"], ["DEVELOP", "14"], ["SYSTEM", "22"], ["UTILITY", "31"]]
    readonly property var mats: [
        ["language", "Browser"], ["terminal", "Terminal"], ["folder", "Files"],
        ["music_note", "Music"], ["code", "Editor"], ["settings", "Settings"]
    ]

    Rectangle {
        anchors.fill: parent
        color: Tokens.paper
    }

    Column {
        anchors.fill: parent
        anchors.margins: Tokens.s5
        spacing: Tokens.s3

        Item {
            width: parent.width
            height: Tokens.s4
            Text {
                id: folio
                anchors.verticalCenter: parent.verticalCenter
                text: "01 \u00b7 APPLICATIONS"
                color: Tokens.inkMuted
                font.family: Tokens.mono
                font.pixelSize: Tokens.fTiny
                font.letterSpacing: Tokens.trackMark
            }
            Rectangle {
                anchors { left: folio.right; leftMargin: Tokens.s2; right: seal.left; rightMargin: Tokens.s2; verticalCenter: parent.verticalCenter }
                height: Tokens.border
                color: Tokens.line
            }
            Text {
                id: seal
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "\u7573"
                color: Tokens.ink
                font.family: Tokens.jp
                font.pixelSize: Tokens.fSmall
            }
        }

        Text {
            text: "Search applications"
            color: Tokens.inkFaint
            font.family: Tokens.display
            font.pixelSize: 26
        }

        Rectangle {
            width: parent.width
            height: Tokens.border
            color: Tokens.lineStrong
        }

        Row {
            spacing: Tokens.s1
            Repeater {
                model: root.sections
                delegate: Rectangle {
                    id: chip
                    required property var modelData
                    required property int index
                    width: chipRow.implicitWidth + Tokens.s2 * 2
                    height: 18
                    radius: Tokens.radius
                    color: chip.index === 0 ? Tokens.bone : "transparent"
                    border.width: chip.index === 0 ? 0 : Tokens.border
                    border.color: Tokens.line
                    Row {
                        id: chipRow
                        anchors.centerIn: parent
                        spacing: 3
                        Text {
                            text: chip.modelData[0]
                            color: chip.index === 0 ? Tokens.inkOnBone : Tokens.inkDim
                            font.family: Tokens.mono
                            font.pixelSize: 8
                            font.letterSpacing: Tokens.trackLabel
                        }
                        Text {
                            text: chip.modelData[1]
                            color: chip.index === 0 ? Tokens.inkOnBoneDim : Tokens.inkFaint
                            font.family: Tokens.mono
                            font.pixelSize: 7
                        }
                    }
                }
            }
        }

        Row {
            spacing: 0
            Repeater {
                model: root.mats
                delegate: Item {
                    id: mat
                    required property var modelData
                    required property int index
                    width: 670 / 6
                    height: 92
                    Rectangle {
                        id: plate
                        anchors.fill: parent
                        anchors.margins: 3
                        radius: Tokens.radius
                        color: mat.index === 1 ? Tokens.tint10 : "transparent"
                    }
                    CornerTicks {
                        anchors.fill: plate
                        visible: mat.index === 1
                        arm: 9
                        color: Tokens.ink
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 18
                        text: mat.modelData[0]
                        color: mat.index === 1 ? Tokens.ink : Tokens.inkDim
                        font.family: "Material Symbols Rounded"
                        font.pixelSize: 30
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        y: 60
                        text: mat.modelData[1]
                        color: mat.index === 1 ? Tokens.ink : Tokens.inkDim
                        font.family: Tokens.ui
                        font.pixelSize: 11
                    }
                }
            }
        }
    }
}
