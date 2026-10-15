import "../../../services"
import ".."
import "."
import QtQuick

RippleButton {
    id: root
    property string buttonIcon: ""
    property real buttonSize: 40
    property real iconSize: root.buttonSize >= 32 ? Appearance.font.pixelSize.larger
        : root.buttonSize >= 28 ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.normal
    property real iconFill: 0
    property bool animateChange: false
    property string tooltip: ""
    property color colText: root.toggled ? Appearance.colors.colOnSecondaryContainer : Appearance.colors.colOnLayer1

    implicitWidth: root.buttonSize
    implicitHeight: root.buttonSize
    buttonRadius: Appearance.rounding.full
    colBackground: "transparent"
    colBackgroundHover: Appearance.colors.colLayer1Hover
    colRipple: Appearance.colors.colLayer1Active
    colBackgroundToggled: Appearance.colors.colSecondaryContainer
    colBackgroundToggledHover: Appearance.colors.colSecondaryContainerHover
    colRippleToggled: Appearance.colors.colSecondaryContainerActive

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.buttonIcon
        iconSize: root.iconSize
        fill: root.iconFill
        color: root.colText
        animateChange: root.animateChange
    }

    Loader {
        active: root.tooltip.length > 0
        sourceComponent: StyledToolTip {
            parent: root
            text: root.tooltip
        }
    }
}
