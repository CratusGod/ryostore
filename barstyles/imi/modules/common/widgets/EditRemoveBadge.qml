import QtQuick
import ".."

RippleButton {
    id: root

    implicitWidth: 18
    implicitHeight: 18
    buttonRadius: Appearance.rounding.full
    colBackground: Appearance.m3colors.m3errorContainer
    colBackgroundHover: Appearance.colors.colErrorHover
    colRipple: Appearance.colors.colErrorActive

    contentItem: MaterialSymbol {
        anchors.centerIn: parent
        horizontalAlignment: Text.AlignHCenter
        text: "close"
        iconSize: 12
        color: Appearance.m3colors.m3onErrorContainer
    }
}
