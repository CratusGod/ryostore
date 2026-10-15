import QtQuick
import QtQuick.Layouts
import ".."
import "."

RippleButton {
    id: chip
    property string label
    property string chipIcon: ""
    property string trailingIcon: ""
    implicitHeight: 32
    implicitWidth: chipRow.implicitWidth + Appearance.spacing.space200
    buttonRadius: Appearance.rounding.small
    colBackground: Appearance.colors.colLayer2
    colBackgroundToggled: Appearance.colors.colSecondaryContainer

    contentItem: RowLayout {
        id: chipRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.space50

        MaterialSymbol {
            visible: chip.chipIcon.length > 0
            text: chip.chipIcon
            iconSize: Appearance.font.pixelSize.normal
            color: chip.toggled
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer2
        }
        StyledText {
            textFormat: Text.PlainText
            text: chip.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: chip.toggled
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer2
        }
        MaterialSymbol {
            visible: chip.trailingIcon.length > 0
            text: chip.trailingIcon
            iconSize: Appearance.font.pixelSize.normal
            color: chip.toggled
                ? Appearance.colors.colOnSecondaryContainer
                : Appearance.colors.colOnLayer2
        }
    }
}
