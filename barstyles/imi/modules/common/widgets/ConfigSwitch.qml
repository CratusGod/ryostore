import "."
import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RippleButton {
    id: root
    property string buttonIcon
    property string description: ""
    property string infoText: ""
    property alias iconSize: catalogueRow.rowIconSize
    property alias detailContent: catalogueRow.detailContent
    property alias titleContent: catalogueRow.titleContent
    property alias trailingContent: catalogueRow.trailingContent
    signal toggleRequested()
    colBackgroundHover: "transparent"


    Layout.fillWidth: true
    implicitHeight: contentItem.implicitHeight + 8 
    font.pixelSize: Appearance.font.pixelSize.small

    onClicked: root.toggleRequested()

    contentItem: CatalogueRow {
        id: catalogueRow
        rowIcon: root.buttonIcon
        rowIconSize: Appearance.font.pixelSize.larger
        title: root.text
        titleFont: root.font
        description: root.description
        infoText: root.infoText

        affordance: [
            StyledSwitch {
                id: switchWidget
                down: root.down
                Layout.fillWidth: false
                checkable: false
                checked: root.checked
                onClicked: root.clicked()
            }
        ]
    }
}
