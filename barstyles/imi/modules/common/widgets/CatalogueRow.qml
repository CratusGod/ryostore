import QtQuick
import QtQuick.Layouts
import ".."
import "."

ColumnLayout {
    id: root

    property string rowIcon: ""
    property real rowIconSize: Appearance.font.pixelSize.larger
    property color rowIconColor: Appearance.colors.colOnSecondaryContainer
    property Component iconComponent: null

    property string title: ""
    property alias titleFont: titleLabel.font
    property color titleColor: Appearance.colors.colOnSecondaryContainer
    property bool titleFillsWidth: false
    property bool titleElides: false

    property string description: ""
    property color descriptionColor: Appearance.colors.colSubtext
    property bool descriptionWraps: true

    property string infoText: ""

    property alias titleContent: titleRow.data
    property alias trailingContent: trailingRow.data
    property alias affordance: affordanceRow.data
    property alias detailContent: detailRow.data

    property real rowSpacing: Appearance.spacing.space150

    spacing: 0


    Component {
        id: glyphIcon
        Item {
            implicitWidth: glyph.implicitWidth
            MaterialSymbol {
                id: glyph
                anchors.centerIn: parent
                text: root.rowIcon
                iconSize: root.rowIconSize
                color: root.rowIconColor
            }
        }
    }

    Component {
        id: customIcon
        Item {
            implicitWidth: customIconLoader.implicitWidth
            Loader {
                id: customIconLoader
                anchors.centerIn: parent
                sourceComponent: root.iconComponent
            }
        }
    }

    RowLayout {
        id: mainRow
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: root.rowSpacing

        Loader {
            Layout.alignment: Qt.AlignVCenter
            active: root.iconComponent !== null || root.rowIcon.length > 0
            visible: active
            sourceComponent: root.iconComponent !== null ? customIcon : glyphIcon
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space100

                StyledText {
                    id: titleLabel
                    Layout.fillWidth: root.titleFillsWidth
                    text: root.title
                    textFormat: Text.PlainText
                    color: root.titleColor
                    elide: root.titleElides ? Text.ElideRight : Text.ElideNone
                }
                RowLayout {
                    id: titleRow
                    Layout.alignment: Qt.AlignBaseline
                    spacing: Appearance.spacing.space50
                }
                Item {
                    visible: !root.titleFillsWidth
                    Layout.fillWidth: !root.titleFillsWidth
                }
            }

            StyledText {
                id: descriptionLabel
                Layout.fillWidth: true
                visible: root.description.length > 0
                text: root.description
                textFormat: Text.PlainText
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: root.descriptionColor
                wrapMode: root.descriptionWraps ? Text.Wrap : Text.NoWrap
                elide: root.descriptionWraps ? Text.ElideNone : Text.ElideRight
            }
        }

        InfoTooltipIcon {
            tooltipText: root.infoText
        }

        RowLayout {
            id: trailingRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.space50
        }

        RowLayout {
            id: affordanceRow
            Layout.alignment: Qt.AlignVCenter
            spacing: Appearance.spacing.space50
        }
    }

    RowLayout {
        id: detailRow
        Layout.fillWidth: true
        Layout.fillHeight: false
        Layout.topMargin: detailRow.children.length > 0
            ? Appearance.spacing.space100 : 0
        spacing: Appearance.spacing.space50
    }
}
