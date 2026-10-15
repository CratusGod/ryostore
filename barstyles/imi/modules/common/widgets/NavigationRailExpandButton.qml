import QtQuick
import QtQuick.Layouts
import ".."
import "."

IconButton {
    id: root
    Layout.alignment: Qt.AlignLeft
    Layout.leftMargin: Appearance.spacing.space100
    iconSize: Appearance.font.pixelSize.hugeass
    buttonIcon: root.parent.expanded ? "menu_open" : "menu"
    downAction: () => {
        parent.expanded = !parent.expanded;
    }

    rotation: root.parent.expanded ? 0 : -180
    Behavior on rotation {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }
}
