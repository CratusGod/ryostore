pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "phone_cards.js" as PhoneCards

PhoneSubPage {
    id: root

    title: Translation.tr("Android Apps")

    property string query: ""

    readonly property var filteredApps: PhoneCards.filterApps(PhoneScrcpy.apps, root.query)

    readonly property var adbDevice: PhoneDeps.ready ? PhoneDeps.adbDevice : undefined
    readonly property bool adbOffline: PhoneScrcpy.appModeSupported && adbPanel.shown

    readonly property var appSessions: {
        const rows = [];
        const count = PhoneScrcpy.sessionCount;
        for (let index = 0; index < count; index++) {
            const row = PhoneScrcpy.sessions.get(index);
            if (row.type === "app")
                rows.push({ id: row.id, package: row.package, title: row.title });
        }
        return rows;
    }

    function askForApps(): void {
        if (PhoneScrcpy.appModeSupported && PhoneScrcpy.apps.length === 0 && !PhoneScrcpy.appsLoading)
            PhoneScrcpy.refreshApps();
    }

    Component.onCompleted: root.askForApps()

    Connections {
        target: PhoneDeps
        function onAdbDeviceChanged() {
            if (PhoneDeps.adbDevice)
                root.askForApps();
        }
    }

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
                enabled: PhoneScrcpy.appModeSupported
                placeholderText: Translation.tr("Search apps…")
                onTextChanged: root.query = searchField.text
            }

            IconButton {
                enabled: PhoneScrcpy.appModeSupported && !PhoneScrcpy.appsLoading
                buttonIcon: "refresh"
                buttonSize: 40
                colBackground: Appearance.colors.colLayer3
                colBackgroundHover: Appearance.colors.colLayer3Hover
                colRipple: Appearance.colors.colLayer3Active
                colText: Appearance.colors.colOnLayer3
                tooltip: Translation.tr("Ask the phone for its app list")
                onClicked: PhoneScrcpy.refreshApps()
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.leftMargin: Appearance.spacing.space50
            visible: !root.adbOffline
            text: {
                if (!PhoneScrcpy.appModeSupported)
                    return Translation.tr("App Mode needs scrcpy 4.0 or newer");
                if (PhoneScrcpy.appsLoading)
                    return Translation.tr("Reading the phone's app list…");
                if (PhoneScrcpy.appsError.length > 0)
                    return PhoneScrcpy.appsError;
                return Translation.tr("%1 of %2 apps").arg(root.filteredApps.length).arg(PhoneScrcpy.apps.length);
            }
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: PhoneScrcpy.appsError.length > 0 ? Appearance.colors.colError : Appearance.colors.colSubtext
            wrapMode: Text.WordWrap
        }

        PhoneAdbPairPanel {
            id: adbPanel
            Layout.fillWidth: true
            visible: PhoneScrcpy.appModeSupported && adbPanel.shown
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: root.appSessions.length > 0
            spacing: Appearance.spacing.space50

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space100

                StyledText {
                    Layout.fillWidth: true
                    Layout.leftMargin: Appearance.spacing.space50
                    text: Translation.tr("Active sessions (%1)").arg(root.appSessions.length)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colSubtext
                }

                RippleButton {
                    Layout.preferredHeight: Appearance.font.pixelSize.huge + Appearance.spacing.space50
                    buttonRadius: Appearance.rounding.small
                    colBackground: "transparent"
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive
                    onClicked: PhoneScrcpy.stopAllApps()

                    contentItem: StyledText {
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Translation.tr("Stop all")
                        font.pixelSize: Appearance.font.pixelSize.smallest
                        font.weight: Font.DemiBold
                        color: Appearance.colors.colError
                    }
                }
            }

            Repeater {
                model: root.appSessions

                delegate: Rectangle {
                    id: sessionRow
                    required property var modelData

                    Layout.fillWidth: true
                    Layout.preferredHeight: sessionLayout.implicitHeight + Appearance.spacing.space100
                    radius: Appearance.rounding.normal
                    color: Appearance.colors.colPrimaryContainer

                    RowLayout {
                        id: sessionLayout
                        anchors {
                            left: parent.left
                            right: parent.right
                            verticalCenter: parent.verticalCenter
                            leftMargin: Appearance.spacing.space125
                            rightMargin: Appearance.spacing.space75
                        }
                        spacing: Appearance.spacing.space100

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "play_circle"
                            fill: 1
                            iconSize: Appearance.font.pixelSize.large
                            color: Appearance.colors.colOnPrimaryContainer
                        }

                        StyledText {
                            Layout.fillWidth: true
                            textFormat: Text.PlainText
                            text: PhoneCards.appLabel({ package: sessionRow.modelData.package })
                            font.pixelSize: Appearance.font.pixelSize.small
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                            elide: Text.ElideRight
                        }

                        DialogButton {
                            buttonText: Translation.tr("Focus")
                            colBackground: Appearance.colors.colPrimary
                            fontWeight: Font.DemiBold
                            colBackgroundHover: Appearance.colors.colPrimaryHover
                            colRipple: Appearance.colors.colPrimaryActive
                            colText: Appearance.colors.colOnPrimary
                            onClicked: PhoneScrcpy.focusApp(sessionRow.modelData.package)
                        }

                        IconButton {
                            buttonIcon: "close"
                            buttonSize: 32
                            colBackground: Appearance.colors.colErrorContainer
                            colBackgroundHover: Appearance.colors.colErrorContainerHover
                            colRipple: Appearance.colors.colErrorContainerActive
                            colText: Appearance.colors.colOnErrorContainer
                            tooltip: Translation.tr("Close this session")
                            onClicked: PhoneScrcpy.stopApp(sessionRow.modelData.package)
                        }
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            visible: favouriteRepeater.count > 0
            spacing: Appearance.spacing.space50

            StyledText {
                Layout.leftMargin: Appearance.spacing.space50
                text: Translation.tr("Favourites")
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.weight: Font.DemiBold
                color: Appearance.colors.colSubtext
            }

            Flow {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space50

                Repeater {
                    id: favouriteRepeater
                    model: PhoneCards.filterApps(PhoneScrcpy.apps, "")
                        .filter(app => PhoneScrcpy.isFavorite(app.package))

                    delegate: RippleButton {
                        id: favouriteChip
                        required property var modelData

                        readonly property bool running: PhoneScrcpy.isAppRunning(favouriteChip.modelData.package)
                        implicitHeight: Appearance.font.pixelSize.huge + Appearance.spacing.space150
                        buttonRadius: Appearance.rounding.full
                        colBackground: favouriteChip.running ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer3
                        colBackgroundHover: favouriteChip.running ? Appearance.colors.colPrimaryContainerHover : Appearance.colors.colLayer3Hover
                        colRipple: favouriteChip.running ? Appearance.colors.colPrimaryContainerActive : Appearance.colors.colLayer3Active
                        onClicked: PhoneScrcpy.launchApp(favouriteChip.modelData.package)

                        contentItem: RowLayout {
                            spacing: Appearance.spacing.space50

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: "android"
                                iconSize: Appearance.font.pixelSize.small
                                color: favouriteChip.running
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnLayer3
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                textFormat: Text.PlainText
                                text: PhoneCards.appLabel(favouriteChip.modelData)
                                font.pixelSize: Appearance.font.pixelSize.smaller
                                color: favouriteChip.running
                                    ? Appearance.colors.colOnPrimaryContainer
                                    : Appearance.colors.colOnLayer3
                            }
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            StyledListView {
                id: appList
                anchors.fill: parent
                clip: true
                spacing: Appearance.spacing.space50
                model: root.filteredApps
                animateAppearance: false
                visible: root.filteredApps.length > 0

                delegate: Rectangle {
                    id: appRow
                    required property var modelData

                    readonly property bool running: PhoneScrcpy.isAppRunning(appRow.modelData.package)

                    width: appList.width
                    height: Appearance.font.pixelSize.huge * 2 + Appearance.spacing.space100
                    radius: Appearance.rounding.normal
                    color: appRow.running ? Appearance.colors.colPrimaryContainer : Appearance.colors.colLayer2

                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    RippleButton {
                        anchors.fill: parent
                        buttonRadius: Appearance.rounding.normal
                        colBackground: "transparent"
                        colBackgroundHover: Appearance.colors.colLayer3Hover
                        colRipple: Appearance.colors.colLayer3Active
                        onClicked: PhoneScrcpy.launchApp(appRow.modelData.package)

                        contentItem: CatalogueRow {
                            rowSpacing: Appearance.spacing.space125

                            iconComponent: Component {
                                MaterialShapeWrappedMaterialSymbol {
                                    text: "android"
                                    wrappedShape: MaterialShape.Shape.Cookie9Sided
                                    iconSize: Appearance.font.pixelSize.small
                                    padding: Appearance.spacing.space75
                                    color: appRow.running
                                        ? Appearance.colors.colPrimary
                                        : Appearance.colors.colSecondaryContainer
                                    colSymbol: appRow.running
                                        ? Appearance.colors.colOnPrimary
                                        : Appearance.colors.colOnSecondaryContainer
                                }
                            }

                            title: PhoneCards.appLabel(appRow.modelData)
                            titleFont.pixelSize: Appearance.font.pixelSize.small
                            titleFont.weight: Font.DemiBold
                            titleColor: appRow.running
                                ? Appearance.colors.colOnPrimaryContainer
                                : Appearance.colors.colOnLayer2
                            titleFillsWidth: true
                            titleElides: true
                            description: appRow.modelData.package
                            descriptionWraps: false

                            trailingContent: [
                                IconButton {
                                    id: starButton
                                    readonly property bool favourite: PhoneScrcpy.isFavorite(appRow.modelData.package)

                                    buttonIcon: starButton.favourite ? "star" : "star_outline"
                                    animateChange: true
                                    buttonSize: 32
                                    iconFill: starButton.favourite ? 1 : 0
                                    colText: starButton.favourite ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                    tooltip: starButton.favourite
                                        ? Translation.tr("Remove from favourites")
                                        : Translation.tr("Add to favourites")
                                    onClicked: PhoneScrcpy.toggleFavorite(appRow.modelData.package)
                                }
                            ]

                            affordance: [
                                MaterialSymbol {
                                    text: appRow.running ? "open_in_new" : "play_arrow"
                                    iconSize: Appearance.font.pixelSize.larger
                                    color: appRow.running ? Appearance.colors.colPrimary : Appearance.colors.colSubtext
                                }
                            ]
                        }
                    }
                }
            }

            PagePlaceholder {
                anchors.fill: parent
                shown: root.filteredApps.length === 0 && !root.adbOffline
                dropIconWhenCramped: true
                descriptionMaximumWidth: Appearance.font.pixelSize.small * 21
                descriptionHorizontalAlignment: Text.AlignHCenter
                icon: PhoneScrcpy.appModeSupported ? "apps" : "warning"
                shape: MaterialShape.Shape.Ghostish
                title: {
                    if (!PhoneScrcpy.appModeSupported)
                        return Translation.tr("App Mode is not available");
                    if (PhoneScrcpy.appsLoading)
                        return Translation.tr("Reading the app list…");
                    if (root.query.length > 0)
                        return Translation.tr("No app matches");
                    return Translation.tr("No apps yet");
                }
                description: {
                    if (!PhoneScrcpy.appModeSupported)
                        return Translation.tr("scrcpy 4.0 or newer is needed to start one app on a display of its own.");
                    if (PhoneScrcpy.appsLoading)
                        return Translation.tr("scrcpy is asking the phone what it has installed.");
                    if (root.query.length > 0)
                        return Translation.tr("Try part of a name or a package.");
                    return Translation.tr("The phone answered with no apps. Unlock its screen and refresh to ask again.");
                }
            }
        }
    }
}
