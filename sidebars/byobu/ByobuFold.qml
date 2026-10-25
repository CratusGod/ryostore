pragma ComponentBehavior: Bound

import QtQuick
import Ryoku.Ui.Singletons

Item {
    id: root

    required property real s
    required property string label
    default property alias foldContent: body.data

    implicitHeight: foldMark.height + Tokens.s2 * s + body.childrenRect.height

    Item {
        id: foldMark
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: (Tokens.fMicro + Tokens.s2) * root.s

        Rectangle {
            anchors.left: parent.left
            anchors.right: mark.left
            anchors.rightMargin: Tokens.s2 * root.s
            anchors.verticalCenter: parent.verticalCenter
            height: Tokens.border
            color: Tokens.lineSoft
        }

        Text {
            id: mark
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: Tokens.inkMuted
            font.family: Tokens.mono
            font.pixelSize: Tokens.fTiny * root.s
            font.letterSpacing: Tokens.trackLabel * root.s
            font.capitalization: Font.AllUppercase
        }

        Rectangle {
            anchors.left: mark.right
            anchors.leftMargin: Tokens.s2 * root.s
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: Tokens.border
            color: Tokens.lineSoft
        }
    }

    Item {
        id: body
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: foldMark.bottom
        anchors.topMargin: Tokens.s2 * root.s
        height: childrenRect.height
    }
}
