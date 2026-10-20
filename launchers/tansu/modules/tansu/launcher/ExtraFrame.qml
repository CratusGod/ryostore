import QtQuick
import "../../../modules/common"
import "../../../modules/common/widgets"

Item {
    id: root

    default property alias content: inner.data
    property real radius: 24
    property bool tape: true
    property color tapeLeft: ScrapbookTheme.tapeTeal
    property color tapeRight: ScrapbookTheme.tapeMint

    property real appear: 0

    opacity: appear
    transform: Translate { y: (1 - root.appear) * 10 }

    Component.onCompleted: appearAnim.start()

    NumberAnimation {
        id: appearAnim
        target: root
        property: "appear"
        from: 0
        to: 1
        duration: 200
        easing.type: Easing.OutCubic
    }

    Rectangle {
        x: Theme.shadowOffset
        y: Theme.shadowOffset
        width: root.width
        height: root.height
        radius: root.radius
        color: Theme.lineShadow
    }

    Rectangle {
        id: face
        anchors.fill: parent
        radius: root.radius
        color: Theme.colBg
        border.width: Theme.borderWidth
        border.color: Theme.line
        clip: true
        antialiasing: true

        // eats clicks on the card's own padding so they don't fall through
        // to the launcher's click-outside-to-close
        MouseArea {
            anchors.fill: parent
        }

        Item {
            id: inner
            anchors.fill: parent
            anchors.margins: Theme.borderWidth
        }
    }

    WashiTape {
        visible: root.tape
        x: 30
        y: -12
        width: 68
        height: 22
        rotation: -6
        color: root.tapeLeft
    }
    WashiTape {
        visible: root.tape
        x: root.width - 30 - 68
        y: -12
        width: 68
        height: 22
        rotation: 5
        color: root.tapeRight
    }
}
