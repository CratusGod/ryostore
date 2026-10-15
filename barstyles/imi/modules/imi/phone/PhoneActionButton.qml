import "../../common"
import "../../common/widgets"
import QtQuick

RippleButton {
    id: root
    property string glyph
    property string label

    implicitWidth: 48
    implicitHeight: 48
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.colors.colPrimaryContainer
    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
    colRipple: Appearance.colors.colPrimaryContainerActive

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        text: root.glyph
        iconSize: Appearance.font.pixelSize.huge
        color: Appearance.colors.colOnPrimaryContainer
    }

    StyledToolTip {
        text: root.label
    }
}
