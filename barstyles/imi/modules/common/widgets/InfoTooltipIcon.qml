import ".."
import QtQuick

MaterialSymbol {
    id: root

    property string tooltipText: ""
    readonly property alias hovered: hoverHandler.hovered

    visible: root.tooltipText.length > 0
    text: "info"
    fill: 0
    iconSize: Appearance.font.pixelSize.large
    color: root.hovered ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colSubtext

    Behavior on color {
        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
    }

    HoverHandler {
        id: hoverHandler
        cursorShape: Qt.WhatsThisCursor
    }

    StyledToolTip {
        text: root.tooltipText
    }
}
