import "."
import ".."
import QtQuick
import QtQuick.Layouts
import "../../../services"

RowLayout {
    id: root
    spacing: Appearance.spacing.space150
    Layout.leftMargin: Appearance.spacing.space100
    Layout.rightMargin: Appearance.spacing.space100

    property string text: ""
    property string buttonIcon: ""
    property real value: 0
    property alias stopIndicatorValues: slider.stopIndicatorValues
    property bool usePercentTooltip: true
    property real from: 0
    property real to: 1
    signal valueModified(real newValue)
    property real textWidth: 120
    property bool showLabel: true

    RowLayout {
        id: row
        visible: root.showLabel
        spacing: Appearance.spacing.space150

        OptionalMaterialSymbol {
            id: iconWidget
            icon: root.buttonIcon
            iconSize: Appearance.font.pixelSize.larger
        }
        StyledText {
            id: labelWidget
            Layout.preferredWidth: root.textWidth
            Layout.maximumWidth: root.textWidth
            text: root.text
            elide: Text.ElideRight
            clip: true
            color: Appearance.colors.colOnSecondaryContainer
        }
    }
    StyledSlider {
        id: slider
        Layout.fillWidth: true
        Layout.minimumWidth: 96
        configuration: StyledSlider.Configuration.XS
        usePercentTooltip: root.usePercentTooltip
        value: root.value
        from: Math.min(root.from, root.value)
        to: Math.max(root.to, root.value)
        onMoved: root.valueModified(slider.valueAt(slider.position))
    }
}
