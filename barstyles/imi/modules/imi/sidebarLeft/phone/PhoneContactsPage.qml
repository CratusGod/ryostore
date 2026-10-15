pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import Qt5Compat.GraphicalEffects

PhoneSubPage {
    id: root

    title: Translation.tr("Contacts")

    property string expandedId: ""

    ColumnLayout {
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: Appearance.spacing.space100

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            spacing: Appearance.spacing.space100

            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: "search"
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colSubtext
            }

            ToolbarTextField {
                id: searchField
                Layout.fillWidth: true
                placeholderText: Translation.tr("Search contacts or numbers…")
                onTextChanged: PhoneContacts.query = searchField.text
            }

            IconButton {
                buttonIcon: "refresh"
                buttonSize: 40
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                colText: Appearance.colors.colOnLayer3
                tooltip: Translation.tr("Re-read the phone's contacts")
                onClicked: PhoneContacts.restartMonitor()
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.space50
            text: PhoneContacts.ready
                ? Translation.tr("%1 of %2 contacts").arg(PhoneContacts.filtered.length).arg(PhoneContacts.count)
                : Translation.tr("Syncing…")
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
        }

        RowLayout {
            Layout.fillWidth: true
            visible: PhoneContacts.lastError.length > 0
            spacing: Appearance.spacing.space75

            MaterialSymbol {
                Layout.alignment: Qt.AlignTop
                text: "error"
                fill: 1
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colError
            }
            StyledText {
                Layout.fillWidth: true
                text: PhoneContacts.lastError
                font.pixelSize: Appearance.font.pixelSize.smaller
                color: Appearance.colors.colError
                wrapMode: Text.WordWrap
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: contactList
                anchors.fill: parent
                clip: true
                spacing: Appearance.spacing.space75
                model: PhoneContacts.filtered
                animateAppearance: false
                visible: PhoneContacts.filtered.length > 0

                delegate: ExpandablePanel {
                    id: contactRow
                    required property var modelData
                    readonly property bool favourite: PhoneContacts.isFavorite(contactRow.modelData.id, PhoneContacts.favorites)
                    readonly property var phones: contactRow.modelData.phones ?? []

                    width: contactList.width
                    height: contactRow.implicitHeight
                    expanded: root.expandedId === contactRow.modelData.id
                    headerClickable: true
                    onHeaderClicked: root.expandedId = contactRow.expanded ? "" : contactRow.modelData.id

                    header: [
                        RowLayout {
                            objectName: "contactHeader"
                            Layout.fillWidth: true
                            spacing: Appearance.spacing.space125

                            Rectangle {
                                id: avatar
                                objectName: "contactAvatar"
                                Layout.alignment: Qt.AlignVCenter
                                Layout.preferredWidth: Appearance.font.pixelSize.huge + Appearance.spacing.space200
                                Layout.preferredHeight: avatar.Layout.preferredWidth
                                radius: Appearance.rounding.full
                                color: Appearance.colors.colPrimaryContainer

                                StyledText {
                                    anchors.centerIn: parent
                                    visible: photo.status !== Image.Ready
                                    text: String(contactRow.modelData.displayName || "?").charAt(0).toUpperCase()
                                    font.pixelSize: Appearance.font.pixelSize.normal
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnPrimaryContainer
                                }

                                StyledImage {
                                    id: photo
                                    anchors.fill: parent
                                    source: contactRow.modelData.photo ?? ""
                                    sourceSize.width: avatar.width * 2
                                    sourceSize.height: avatar.height * 2
                                    fillMode: Image.PreserveAspectCrop
                                    layer.enabled: true
                                    layer.effect: OpacityMask {
                                        maskSource: Rectangle {
                                            width: avatar.width
                                            height: avatar.height
                                            radius: avatar.width / 2
                                        }
                                    }
                                }
                            }

                            ColumnLayout {
                                objectName: "contactIdentity"
                                Layout.fillWidth: true
                                Layout.alignment: Qt.AlignVCenter
                                spacing: 0

                                StyledText {
                                    Layout.fillWidth: true
                                    textFormat: Text.PlainText
                                    text: contactRow.modelData.displayName || Translation.tr("Unknown")
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    font.weight: Font.DemiBold
                                    color: Appearance.colors.colOnLayer2
                                    elide: Text.ElideRight
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    textFormat: Text.PlainText
                                    text: {
                                        if (contactRow.modelData.organization)
                                            return contactRow.modelData.organization;
                                        if (contactRow.phones.length > 0)
                                            return contactRow.phones[0].value;
                                        const emails = contactRow.modelData.emails ?? [];
                                        return emails.length > 0 ? emails[0].value : "";
                                    }
                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                    color: Appearance.colors.colSubtext
                                    elide: Text.ElideRight
                                }
                            }

                            IconButton {
                                buttonIcon: contactRow.favourite ? "star" : "star_outline"
                                animateChange: true
                                buttonSize: 32
                                iconFill: contactRow.favourite ? 1 : 0
                                colText: contactRow.favourite ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                tooltip: contactRow.favourite
                                    ? Translation.tr("Remove from favourites")
                                    : Translation.tr("Add to favourites")
                                onClicked: PhoneContacts.toggleFavorite(contactRow.modelData.id)
                            }

                            MaterialSymbol {
                                objectName: "contactChevron"
                                Layout.alignment: Qt.AlignVCenter
                                text: contactRow.expanded ? "expand_less" : "expand_more"
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colSubtext
                                animateChange: true
                            }
                        }
                    ]

                    ColumnLayout {
                        objectName: "contactDetails"
                        Layout.fillWidth: true
                        Layout.leftMargin: Appearance.spacing.space100
                        Layout.rightMargin: Appearance.spacing.space100
                        Layout.bottomMargin: Appearance.spacing.space50
                        spacing: Appearance.spacing.space75

                        Repeater {
                            model: contactRow.phones

                            delegate: RowLayout {
                                id: phoneRow
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Appearance.spacing.space100

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: phoneRow.modelData.type === "mobile" ? "smartphone" : "call"
                                    iconSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colPrimary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    StyledText {
                                        Layout.fillWidth: true
                                        textFormat: Text.PlainText
                                        text: phoneRow.modelData.value
                                        font.pixelSize: Appearance.font.pixelSize.small
                                        color: Appearance.colors.colOnLayer3
                                        elide: Text.ElideRight
                                    }
                                    StyledText {
                                        Layout.fillWidth: true
                                        visible: String(phoneRow.modelData.type || "").length > 0
                                        textFormat: Text.PlainText
                                        text: phoneRow.modelData.type
                                        font.pixelSize: Appearance.font.pixelSize.smallest
                                        color: Appearance.colors.colSubtext
                                    }
                                }

                                IconButton {
                                    buttonIcon: "call"
                                    buttonSize: 32
                                    colBackground: Appearance.colors.colPrimaryContainer
                                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                                    colRipple: Appearance.colors.colPrimaryContainerActive
                                    colText: Appearance.colors.colOnPrimaryContainer
                                    tooltip: Translation.tr("Open the dialer on the phone")
                                    onClicked: PhoneContacts.openDialer(phoneRow.modelData.value)
                                }

                                IconButton {
                                    buttonIcon: "sms"
                                    buttonSize: 32
                                    colBackground: Appearance.colors.colSecondaryContainer
                                    colBackgroundHover: Appearance.colors.colSecondaryContainerHover
                                    colRipple: Appearance.colors.colSecondaryContainerActive
                                    colText: Appearance.colors.colOnSecondaryContainer
                                    tooltip: Translation.tr("Write a message on the phone")
                                    onClicked: PhoneContacts.composeSms(phoneRow.modelData.value)
                                }

                                IconButton {
                                    buttonIcon: "content_copy"
                                    buttonSize: 32
                                    colBackground: Appearance.colors.colLayer4
                                    colBackgroundHover: Appearance.colors.colLayer4Hover
                                    colRipple: Appearance.colors.colLayer4Active
                                    colText: Appearance.colors.colOnLayer4
                                    tooltip: Translation.tr("Copy the number")
                                    onClicked: Quickshell.clipboardText = phoneRow.modelData.value
                                }
                            }
                        }

                        Repeater {
                            model: contactRow.modelData.emails ?? []

                            delegate: RowLayout {
                                id: emailRow
                                required property var modelData

                                Layout.fillWidth: true
                                spacing: Appearance.spacing.space100

                                MaterialSymbol {
                                    Layout.alignment: Qt.AlignVCenter
                                    text: "mail"
                                    iconSize: Appearance.font.pixelSize.large
                                    color: Appearance.colors.colPrimary
                                }
                                StyledText {
                                    Layout.fillWidth: true
                                    textFormat: Text.PlainText
                                    text: emailRow.modelData.value
                                    font.pixelSize: Appearance.font.pixelSize.small
                                    color: Appearance.colors.colOnLayer3
                                    elide: Text.ElideRight
                                }
                                IconButton {
                                    buttonIcon: "content_copy"
                                    buttonSize: 32
                                    colBackground: Appearance.colors.colLayer4
                                    colBackgroundHover: Appearance.colors.colLayer4Hover
                                    colRipple: Appearance.colors.colLayer4Active
                                    colText: Appearance.colors.colOnLayer4
                                    tooltip: Translation.tr("Copy the address")
                                    onClicked: Quickshell.clipboardText = emailRow.modelData.value
                                }
                            }
                        }
                    }
                }
            }

            PagePlaceholder {
                anchors.fill: parent
                shown: PhoneContacts.filtered.length === 0
                dropIconWhenCramped: true
                icon: PhoneContacts.ready ? "person_search" : "sync"
                shape: MaterialShape.Shape.Ghostish
                title: {
                    if (!PhoneContacts.ready)
                        return Translation.tr("Syncing contacts…");
                    if (PhoneContacts.query.length > 0)
                        return Translation.tr("No contact matches");
                    return Translation.tr("No contacts yet");
                }
                description: {
                    if (!PhoneContacts.ready)
                        return Translation.tr("Reading the cards KDE Connect wrote for this phone.");
                    if (PhoneContacts.query.length > 0)
                        return Translation.tr("Try part of a name or a number.");
                    return Translation.tr("Switch Contacts on in KDE Connect on your phone, then sync.");
                }
            }
        }
    }
}
