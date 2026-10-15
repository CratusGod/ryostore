pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "phone_cards.js" as PhoneCards

Item {
    id: root

    property var dependencies: []
    property string detectedDistro: "unknown"
    property string headerTitle: Translation.tr("Missing dependencies")

    signal closeRequested
    signal recheckRequested

    property string selectedDistro: PhoneCards.initialDistro(root.detectedDistro)

    onVisibleChanged: if (root.visible)
        root.selectedDistro = PhoneCards.initialDistro(root.detectedDistro);

    onDependenciesChanged: if (root.visible && root.dependencies.length === 0)
        root.closeRequested();

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onClicked: root.closeRequested()

        Rectangle {
            anchors.fill: parent
            color: Appearance.colors.colScrim
        }
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(parent.width - Appearance.spacing.space200, 420)
        height: Math.min(parent.height - Appearance.spacing.space200,
                         cardColumn.implicitHeight + Appearance.spacing.space200 * 2)
        radius: Appearance.rounding.large
        color: Appearance.colors.colLayer2Base

        MouseArea {
            anchors.fill: parent
        }

        ColumnLayout {
            id: cardColumn
            anchors {
                fill: parent
                margins: Appearance.spacing.space200
            }
            spacing: Appearance.spacing.space150

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space125

                MaterialSymbol {
                    Layout.alignment: Qt.AlignVCenter
                    text: "build"
                    fill: 1
                    iconSize: Appearance.font.pixelSize.huge
                    color: Appearance.colors.colPrimary
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.headerTitle
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnLayer2
                    elide: Text.ElideRight
                }

                IconButton {
                    buttonIcon: "close"
                    buttonSize: 32
                    colBackground: Appearance.colors.colLayer3
                    colBackgroundHover: Appearance.colors.colLayer3Hover
                    colRipple: Appearance.colors.colLayer3Active
                    colText: Appearance.colors.colOnLayer3
                    onClicked: root.closeRequested()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space50

                Repeater {
                    model: PhoneCards.distroPills()

                    delegate: FilterChip {
                        id: pill
                        required property var modelData

                        label: pill.modelData.label
                        toggled: root.selectedDistro === pill.modelData.key
                        onClicked: root.selectedDistro = pill.modelData.key
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                StyledText {
                    Layout.alignment: Qt.AlignVCenter
                    visible: PhoneCards.knownDistro(root.detectedDistro)
                    text: Translation.tr("Detected: %1").arg(root.detectedDistro)
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                }
            }

            StyledFlickable {
                id: dependencyScroll
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentHeight: dependencyColumn.implicitHeight
                clip: true

                ColumnLayout {
                    id: dependencyColumn
                    width: dependencyScroll.width
                    spacing: Appearance.spacing.space100

                    Repeater {
                        model: root.dependencies

                        delegate: Rectangle {
                            id: dependencyRow
                            required property var modelData

                            readonly property string command: PhoneCards.commandFor(dependencyRow.modelData, root.selectedDistro)

                            Layout.fillWidth: true
                            Layout.preferredHeight: dependencyBody.implicitHeight + Appearance.spacing.space125 * 2
                            radius: Appearance.rounding.normal
                            color: Appearance.colors.colLayer3

                            ColumnLayout {
                                id: dependencyBody
                                anchors {
                                    left: parent.left
                                    right: parent.right
                                    verticalCenter: parent.verticalCenter
                                    leftMargin: Appearance.spacing.space125
                                    rightMargin: Appearance.spacing.space125
                                }
                                spacing: Appearance.spacing.space75

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: Appearance.spacing.space100

                                    MaterialSymbol {
                                        Layout.alignment: Qt.AlignTop
                                        text: "error"
                                        fill: 1
                                        iconSize: Appearance.font.pixelSize.large
                                        color: Appearance.colors.colError
                                    }

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: Appearance.spacing.space25

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: dependencyRow.modelData.name
                                            font.pixelSize: Appearance.font.pixelSize.small
                                            font.weight: Font.DemiBold
                                            color: Appearance.colors.colOnLayer3
                                            wrapMode: Text.WordWrap
                                        }
                                        StyledText {
                                            Layout.fillWidth: true
                                            text: dependencyRow.modelData.description
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            color: Appearance.colors.colSubtext
                                            wrapMode: Text.WordWrap
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: commandRow.implicitHeight + Appearance.spacing.space75 * 2
                                    visible: dependencyRow.command.length > 0
                                    radius: Appearance.rounding.small
                                    color: Appearance.colors.colLayer4

                                    RowLayout {
                                        id: commandRow
                                        anchors {
                                            left: parent.left
                                            right: parent.right
                                            verticalCenter: parent.verticalCenter
                                            leftMargin: Appearance.spacing.space100
                                            rightMargin: Appearance.spacing.space75
                                        }
                                        spacing: Appearance.spacing.space75

                                        StyledText {
                                            Layout.fillWidth: true
                                            text: PhoneCards.firstCommand(dependencyRow.command)
                                            font.pixelSize: Appearance.font.pixelSize.smallest
                                            font.family: Appearance.font.family.monospace
                                            color: Appearance.colors.colOnLayer4
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                        }

                                        IconButton {
                                            id: copyButton
                                            property bool copied: false

                                            buttonIcon: copyButton.copied ? "check" : "content_copy"
                                            animateChange: true
                                            buttonSize: 32
                                            iconFill: 1
                                            colBackground: Appearance.colors.colSurfaceContainerHighest
                                            colBackgroundHover: Appearance.colors.colSurfaceContainerHighestHover
                                            colRipple: Appearance.colors.colSurfaceContainerHighestActive
                                            colText: copyButton.copied ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer4
                                            tooltip: Translation.tr("Copy the install command")
                                            onClicked: {
                                                Quickshell.execDetached(PhoneCards.copyArgv(dependencyRow.command));
                                                copyButton.copied = true;
                                                copiedTimer.restart();
                                            }

                                            Timer {
                                                id: copiedTimer
                                                interval: 1500
                                                onTriggered: copyButton.copied = false
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space100

                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("After installing, re-check to verify.")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colSubtext
                    wrapMode: Text.WordWrap
                }

                RippleButton {
                    Layout.preferredHeight: Appearance.font.pixelSize.huge + Appearance.spacing.space100
                    buttonRadius: Appearance.rounding.full
                    colBackground: Appearance.colors.colPrimaryContainer
                    colBackgroundHover: Appearance.colors.colPrimaryContainerHover
                    colRipple: Appearance.colors.colPrimaryContainerActive
                    onClicked: root.recheckRequested()

                    contentItem: RowLayout {
                        spacing: Appearance.spacing.space50

                        MaterialSymbol {
                            Layout.alignment: Qt.AlignVCenter
                            text: "refresh"
                            fill: 1
                            iconSize: Appearance.font.pixelSize.small
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                        StyledText {
                            Layout.alignment: Qt.AlignVCenter
                            text: Translation.tr("Re-check")
                            font.pixelSize: Appearance.font.pixelSize.smallest
                            font.weight: Font.DemiBold
                            color: Appearance.colors.colOnPrimaryContainer
                        }
                    }
                }
            }
        }
    }
}
