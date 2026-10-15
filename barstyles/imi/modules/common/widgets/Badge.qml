import QtQuick
import QtQuick.Layouts
import ".."
import "."

Rectangle {
    id: badge

    property string label
    property string badgeIcon: ""
    property color colBackground: Appearance.colors.colSecondaryContainer
    property color colText: Appearance.colors.colOnSecondaryContainer

    implicitWidth: badgeRow.implicitWidth + Appearance.spacing.space150
    implicitHeight: badgeRow.implicitHeight + Appearance.spacing.space50
    radius: Appearance.rounding.full
    color: badge.colBackground

    RowLayout {
        id: badgeRow
        anchors.centerIn: parent
        spacing: Appearance.spacing.space25

        MaterialSymbol {
            visible: badge.badgeIcon.length > 0
            text: badge.badgeIcon
            iconSize: Appearance.font.pixelSize.small
            color: badge.colText
        }
        StyledText {
            text: badge.label
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: badge.colText
            textFormat: Text.PlainText
        }
    }
}
