import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property real appear: 1

    signal openPage(string id)

    component NavCard: RippleButton {
        id: card
        property string glyph
        property string title
        property string subtitle
        property color colGlyphBackground: Appearance.colors.colPrimaryContainer
        property color colGlyph: Appearance.colors.colOnPrimaryContainer

        implicitHeight: 58
        buttonRadius: Appearance.rounding.normal
        colBackground: Appearance.colors.colLayer3
        colBackgroundHover: Appearance.colors.colLayer3Hover
        colRipple: Appearance.colors.colLayer3Active

        contentItem: CatalogueRow {
            anchors {
                fill: parent
                leftMargin: Appearance.spacing.space150
                rightMargin: Appearance.spacing.space100
            }
            rowSpacing: Appearance.spacing.space125

            iconComponent: Component {
                Rectangle {
                    implicitWidth: 34
                    implicitHeight: 34
                    radius: Appearance.rounding.full
                    color: card.colGlyphBackground

                    MaterialSymbol {
                        anchors.centerIn: parent
                        text: card.glyph
                        iconSize: Appearance.font.pixelSize.larger
                        color: card.colGlyph
                    }
                }
            }

            title: card.title
            titleFont.pixelSize: Appearance.font.pixelSize.small
            titleColor: Appearance.colors.colOnLayer3
            titleFillsWidth: true
            titleElides: true
            description: card.subtitle
            descriptionWraps: false

            affordance: [
                MaterialSymbol {
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    color: Appearance.colors.colSubtext
                }
            ]
        }
    }

    implicitHeight: cardRow.implicitHeight

    RowLayout {
        id: cardRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        spacing: Appearance.spacing.space100

        NavCard {
            id: contactsCard
            Layout.fillWidth: true
            glyph: "contacts"
            colGlyphBackground: Appearance.colors.colPrimaryContainer
            colGlyph: Appearance.colors.colOnPrimaryContainer
            title: Translation.tr("Contacts")
            subtitle: {
                if (!PhoneContacts.ready) return Translation.tr("Syncing…");
                const count = PhoneContacts.count;
                return count === 1
                    ? Translation.tr("1 contact")
                    : Translation.tr("%1 contacts").arg(String(count));
            }
            onClicked: root.openPage("contacts")
        }

        NavCard {
            id: appsCard
            Layout.fillWidth: true
            glyph: "apps"
            colGlyphBackground: Appearance.colors.colSecondaryContainer
            colGlyph: Appearance.colors.colOnSecondaryContainer
            title: Translation.tr("Android Apps")
            subtitle: {
                if (!PhoneScrcpy.available) return Translation.tr("scrcpy is not installed");
                return PhoneScrcpy.appModeSupported
                    ? Translation.tr("scrcpy App Mode")
                    : Translation.tr("Requires scrcpy 4.0+");
            }
            onClicked: root.openPage("apps")
        }
    }
}
