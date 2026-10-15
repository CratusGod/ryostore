import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property string title: ""
    signal back()

    default property alias content: contentHolder.data

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.space100

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.space100

            IconButton {
                id: backButton
                buttonIcon: "arrow_back"
                buttonSize: 40
                colText: Appearance.colors.colOnLayer2
                tooltip: Translation.tr("Back")
                onClicked: root.back()
            }

            StyledText {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.title
                font.pixelSize: Appearance.font.pixelSize.normal
                color: Appearance.colors.colOnLayer2
            }
        }

        ColumnLayout {
            id: contentHolder
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0
        }
    }
}
