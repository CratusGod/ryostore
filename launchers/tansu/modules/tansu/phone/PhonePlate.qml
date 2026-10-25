import QtQuick
import "../../../modules/common"

Item {
    id: root

    default property alias content: inner.data

    property real radius: 28
    property color fill: Theme.pSurface
    property Gradient fillGradient: null
    property real borderW: 3
    property real shadow: 4
    property color line: Theme.pLine
    property color shadowColor: Theme.pLineShadow
    property bool pressed: false

    readonly property real faceW: width - shadow
    readonly property real faceH: height - shadow
    readonly property alias face: face

    Rectangle {
        x: root.shadow
        y: root.shadow
        width: root.faceW
        height: root.faceH
        radius: root.radius
        color: root.shadowColor
        antialiasing: true
    }

    Rectangle {
        id: face

        x: root.pressed ? root.shadow - 1 : 0
        y: root.pressed ? root.shadow - 1 : 0
        width: root.faceW
        height: root.faceH
        radius: root.radius
        color: root.fill
        gradient: root.fillGradient
        border.width: root.borderW
        border.color: root.line
        antialiasing: true

        Behavior on x {
            NumberAnimation {
                duration: 70
                easing.type: Easing.OutCubic
            }
        }
        Behavior on y {
            NumberAnimation {
                duration: 70
                easing.type: Easing.OutCubic
            }
        }

        Item {
            id: inner
            anchors.fill: parent
        }
    }
}
