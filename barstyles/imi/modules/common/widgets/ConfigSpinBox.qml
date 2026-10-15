import "."
import ".."
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root
    property string text: ""
    property string icon
    property string infoText: ""
    property int value: 0
    property alias stepSize: spinBoxWidget.stepSize
    property int from: 0
    property int to: 99
    signal valueModified(int newValue)
    spacing: Appearance.spacing.space150
    Layout.leftMargin: Appearance.spacing.space100
    Layout.rightMargin: Appearance.spacing.space100

    RowLayout {
        spacing: Appearance.spacing.space150
        OptionalMaterialSymbol {
            icon: root.icon
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            id: labelWidget
            Layout.fillWidth: true
            text: root.text
            color: Appearance.colors.colOnSecondaryContainer
            opacity: root.enabled ? 1 : 0.4
        }

        InfoTooltipIcon {
            tooltipText: root.infoText
            opacity: root.enabled ? 1 : 0.4
        }
    }

    StyledSpinBox {
        id: spinBoxWidget
        Layout.fillWidth: false
        from: Math.min(root.from, root.value)
        to: Math.max(root.to, root.value)
        value: root.value
        onUserModified: root.valueModified(spinBoxWidget.value)
    }
}
