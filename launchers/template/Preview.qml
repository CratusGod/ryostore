import QtQuick
import Ryoku.Ui.Singletons

// What Ryoku Settings shows for this launcher: a still, 720 x 250, drawn with
// Ryoku's tokens. Replace it with a picture of your own design.
Item {
    id: root

    property var settings: ({})
    signal editRequested(string key, var value)

    implicitWidth: 720
    implicitHeight: 250

    Rectangle {
        anchors.fill: parent
        color: Tokens.paper
    }

    Rectangle {
        width: 360
        height: 150
        anchors.centerIn: parent
        radius: Tokens.radius
        color: Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.lineStrong

        Column {
            anchors { fill: parent; margins: Tokens.s3 }
            spacing: Tokens.s2
            Text {
                text: "Search"
                color: Tokens.inkFaint
                font.family: Tokens.ui
                font.pixelSize: Tokens.fRow
            }
            Repeater {
                model: ["Browser", "Terminal", "Files"]
                delegate: Rectangle {
                    id: row
                    required property string modelData
                    required property int index
                    width: parent.width
                    height: 26
                    radius: Tokens.radius
                    color: row.index === 0 ? Tokens.tint10 : "transparent"
                    Text {
                        anchors { left: parent.left; leftMargin: Tokens.s2; verticalCenter: parent.verticalCenter }
                        text: row.modelData
                        color: Tokens.ink
                        font.family: Tokens.ui
                        font.pixelSize: Tokens.fSmall
                    }
                }
            }
        }
    }
}
