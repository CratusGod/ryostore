import QtQuick
import "../../.."
import "../../common"

Rectangle {
    id: root

    readonly property real minRun: 48

    color: "transparent"
    border.width: Appearance.borderWidth.standard
    border.color: Appearance.colors.colOutlineVariant
    radius: Appearance.rounding.small
    opacity: 0.6 * GlobalStates.editProgress
    visible: GlobalStates.editProgress > 0
}
