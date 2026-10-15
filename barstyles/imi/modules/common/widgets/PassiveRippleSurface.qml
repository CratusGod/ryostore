import ".."
import "."
import "../functions"
import QtQuick

RippleButton {
    id: root

    property bool hostHovered: false
    property bool hostDown: false
    property point hostPressPoint: Qt.point(width / 2, height / 2)

    passive: true
    transform: []
    interactionMotion.hovered: root.hostHovered
    interactionMotion.down: root.hostDown
    interactionMotion.controlEnabled: true
    buttonColor: root.hostHovered ? root.colBackgroundHover : root.colBackground

    onHostDownChanged: {
        if (root.hostDown)
            root.startRipple(root.hostPressPoint.x, root.hostPressPoint.y);
        else
            root.fadeRipple();
    }
}
