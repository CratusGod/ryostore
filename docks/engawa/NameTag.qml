import QtQuick
import Ryoku.Ui.Singletons

// The name of the app under the pointer, on a paper tag just beyond the beam.
Rectangle {
    id: tag

    required property var plank
    required property string edge

    readonly property bool horizontal: tag.edge === "top" || tag.edge === "bottom"
    readonly property bool shown: tag.plank.hoverName !== ""
    // clear of a magnified, lifted icon
    readonly property real offset: 8 + Math.max(0, tag.plank.iconSize * 0.24 - 11)
    readonly property real along: tag.plank.markLength
        + Math.max(0, tag.plank.hoverIndex) * tag.plank.boardLength + tag.plank.boardLength / 2

    width: label.width + 20
    height: label.implicitHeight + 10
    color: Tokens.paper
    border.width: Tokens.border
    border.color: Tokens.line
    opacity: tag.shown ? 1 : 0
    visible: opacity > 0
    Behavior on opacity { NumberAnimation { duration: Tokens.snap } }

    x: tag.horizontal ? Math.round(tag.plank.x + tag.along - width / 2)
        : tag.edge === "left" ? tag.plank.x + tag.plank.width + tag.offset
        : tag.plank.x - width - tag.offset
    y: !tag.horizontal ? Math.round(tag.plank.y + tag.along - height / 2)
        : tag.edge === "top" ? tag.plank.y + tag.plank.height + tag.offset
        : tag.plank.y - height - tag.offset
    Behavior on x { enabled: tag.shown && tag.horizontal; NumberAnimation { duration: Tokens.snap; easing.type: Tokens.ease } }
    Behavior on y { enabled: tag.shown && !tag.horizontal; NumberAnimation { duration: Tokens.snap; easing.type: Tokens.ease } }

    Text {
        id: label
        anchors.centerIn: parent
        width: Math.min(implicitWidth, 160)
        elide: Text.ElideRight
        text: tag.plank.hoverName.toUpperCase()
        color: Tokens.ink
        font.family: Tokens.ui
        font.pixelSize: Tokens.fMicro
        font.letterSpacing: Tokens.trackLabel
    }
}
