import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

TextField {
    id: filterField

    property alias colBackground: background.color
    property bool focusRing: false
    property bool ringShown: filterField.focusRing && filterField.activeFocus
    property color colRing: Appearance.colors.colPrimary
    property string leadingIcon: ""

    Layout.fillHeight: true
    implicitWidth: 200
    padding: Appearance.spacing.space150
    leftPadding: filterField.leadingIcon.length > 0
        ? Appearance.spacing.space150 + leadingGlyph.implicitWidth + Appearance.spacing.space100
        : Appearance.spacing.space150

    placeholderTextColor: Appearance.colors.colSubtext
    color: Appearance.colors.colOnLayer1
    font {
        family: Appearance.font.family.main
        pixelSize: Appearance.font.pixelSize.small
        hintingPreference: Font.PreferFullHinting
        variableAxes: Appearance.font.variableAxes.main
    }
    renderType: Text.NativeRendering
    selectedTextColor: Appearance.colors.colOnSecondaryContainer
    selectionColor: Appearance.colors.colSecondaryContainer

    background: Rectangle {
        id: background
        color: Appearance.colors.colLayer1
        radius: Appearance.rounding.full
        border.width: filterField.ringShown ? Appearance.borderWidth.emphasis : 0
        border.color: filterField.colRing
    }

    MaterialSymbol {
        id: leadingGlyph
        visible: filterField.leadingIcon.length > 0
        anchors {
            left: parent.left
            leftMargin: Appearance.spacing.space150
            verticalCenter: parent.verticalCenter
        }
        text: filterField.leadingIcon
        iconSize: Appearance.font.pixelSize.larger
        color: Appearance.colors.colSubtext
    }
}
