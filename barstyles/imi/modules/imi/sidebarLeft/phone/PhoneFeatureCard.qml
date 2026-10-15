pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../../services"
import "../../../common"
import "../../../common/widgets"
import "../../../common/functions"

Item {
    id: root

    property string cardState: "ready"
    property string iconName: "smart_display"
    property var iconShape: MaterialShape.Shape.Cookie9Sided
    property string title: ""
    property string subtitle: ""
    property string detailLine: ""
    property string lastError: ""
    property var inlineActions: []
    property bool dropEnabled: false
    property bool hasSettings: false

    signal settingsClicked
    signal stopClicked
    signal filesDropped(var urls)

    readonly property bool isActive: root.cardState === "active"
    readonly property bool isConnecting: root.cardState === "connecting"
    readonly property bool isMuted: root.cardState === "unavailable" || root.cardState === "offline"
    readonly property color colForeground: root.isMuted
        ? Appearance.colors.colOnLayer3
        : Appearance.colors.colOnPrimaryContainer

    implicitHeight: root.isActive ? cardColumn.implicitHeight + Appearance.spacing.space100 * 2 : cardHeight
    readonly property real cardHeight: 68

    Behavior on implicitHeight {
        animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
    }

    signal clicked

    RippleButton {
        id: cardSurface
        anchors.fill: parent
        buttonRadius: Appearance.rounding.normal
        colBackground: root.isMuted ? Appearance.colors.colLayer3 : Appearance.colors.colPrimaryContainer
        colBackgroundHover: root.isMuted ? Appearance.colors.colLayer3Hover : Appearance.colors.colPrimaryContainerHover
        colRipple: root.isMuted ? Appearance.colors.colLayer3Active : Appearance.colors.colPrimaryContainerActive
        onClicked: root.clicked()

        Behavior on colBackground {
            animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
        }
    }


    ColumnLayout {
        id: cardColumn
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            leftMargin: Appearance.spacing.space150
            rightMargin: Appearance.spacing.space150
            topMargin: Appearance.spacing.space100
        }
        spacing: Appearance.spacing.space75

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: root.cardHeight - Appearance.spacing.space100 * 2
            spacing: Appearance.spacing.space125

            MaterialShapeWrappedMaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                text: root.cardState === "unavailable" ? "download"
                    : root.cardState === "offline" ? "cast"
                    : root.iconName
                wrappedShape: root.iconShape
                iconSize: Appearance.font.pixelSize.large
                padding: Appearance.spacing.space125
                color: ColorUtils.transparentize(root.colForeground, 0.82)
                colSymbol: root.colForeground
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

                StyledText {
                    Layout.fillWidth: true
                    text: root.title
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.DemiBold
                    color: root.colForeground
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }

                StyledText {
                    Layout.fillWidth: true
                    text: root.subtitle
                    font.pixelSize: Appearance.font.pixelSize.smaller
                    color: ColorUtils.transparentize(root.colForeground, 0.3)
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            IconButton {
                id: settingsButton
                objectName: "cardSettingsChip"
                Layout.alignment: Qt.AlignVCenter
                visible: root.hasSettings
                buttonIcon: "tune"
                buttonSize: 32
                colBackground: ColorUtils.transparentize(root.colForeground, 0.85)
                colBackgroundHover: ColorUtils.transparentize(root.colForeground, 0.72)
                colRipple: ColorUtils.transparentize(root.colForeground, 0.62)
                colText: root.colForeground
                tooltip: Translation.tr("Settings")
                onClicked: root.settingsClicked()
            }

            Item {
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredWidth: Appearance.font.pixelSize.huge
                Layout.preferredHeight: Appearance.font.pixelSize.huge

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: !root.isActive && !root.isConnecting
                    text: "chevron_right"
                    iconSize: Appearance.font.pixelSize.larger
                    color: ColorUtils.transparentize(root.colForeground, 0.5)
                }

                MaterialSymbol {
                    anchors.centerIn: parent
                    visible: root.isActive
                    text: "check_circle"
                    fill: 1
                    iconSize: Appearance.font.pixelSize.larger
                    color: root.colForeground
                }

                MaterialLoadingIndicator {
                    anchors.centerIn: parent
                    visible: root.isConnecting
                    loading: root.isConnecting
                    implicitSize: Appearance.font.pixelSize.huge
                    colBg: "transparent"
                    colShape: root.colForeground
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Appearance.spacing.space100
            visible: root.isActive
            spacing: Appearance.spacing.space75

            StyledText {
                Layout.fillWidth: true
                visible: root.detailLine.length > 0
                text: root.detailLine
                font.pixelSize: Appearance.font.pixelSize.smallest
                font.family: Appearance.font.family.monospace
                color: ColorUtils.transparentize(root.colForeground, 0.2)
                elide: Text.ElideMiddle
                maximumLineCount: 1
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: errorText.implicitHeight + Appearance.spacing.space100
                visible: root.lastError.length > 0
                radius: Appearance.rounding.small
                color: Appearance.colors.colErrorContainer

                StyledText {
                    id: errorText
                    anchors {
                        fill: parent
                        leftMargin: Appearance.spacing.space100
                        rightMargin: Appearance.spacing.space100
                    }
                    verticalAlignment: Text.AlignVCenter
                    text: root.lastError
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnErrorContainer
                    elide: Text.ElideRight
                    maximumLineCount: 1
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Appearance.spacing.space75

                RippleButton {
                    id: stopButton
                    Layout.fillWidth: true
                    Layout.preferredHeight: Appearance.font.pixelSize.huge + Appearance.spacing.space150
                    buttonRadius: Appearance.rounding.normal
                    colBackground: Appearance.colors.colErrorContainer
                    colBackgroundHover: Appearance.colors.colErrorContainerHover
                    colRipple: Appearance.colors.colErrorContainerActive
                    onClicked: root.stopClicked()

                    contentItem: Item {
                        implicitWidth: stopRow.implicitWidth
                        implicitHeight: stopRow.implicitHeight

                        RowLayout {
                            id: stopRow
                            anchors.centerIn: parent
                            spacing: Appearance.spacing.space75

                            MaterialSymbol {
                                Layout.alignment: Qt.AlignVCenter
                                text: "stop_circle"
                                fill: 1
                                iconSize: Appearance.font.pixelSize.larger
                                color: Appearance.colors.colOnErrorContainer
                            }
                            StyledText {
                                Layout.alignment: Qt.AlignVCenter
                                text: Translation.tr("Stop")
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.weight: Font.DemiBold
                                color: Appearance.colors.colOnErrorContainer
                            }
                        }
                    }
                }

                Repeater {
                    model: root.inlineActions

                    delegate: RippleButton {
                        id: chip
                        required property var modelData

                        Layout.preferredWidth: Appearance.font.pixelSize.huge + Appearance.spacing.space150
                        Layout.preferredHeight: Appearance.font.pixelSize.huge + Appearance.spacing.space150
                        buttonRadius: Appearance.rounding.small
                        colBackground: ColorUtils.transparentize(root.colForeground, 0.82)
                        colBackgroundHover: ColorUtils.transparentize(root.colForeground, 0.7)
                        colRipple: ColorUtils.transparentize(root.colForeground, 0.6)
                        onClicked: {
                            const action = chip.modelData?.action;
                            if (typeof action === "function")
                                action();
                        }

                        contentItem: MaterialSymbol {
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            text: chip.modelData?.icon ?? ""
                            fill: 1
                            iconSize: Appearance.font.pixelSize.larger
                            color: root.colForeground
                            animateChange: true
                        }

                        StyledToolTip {
                            text: chip.modelData?.label ?? ""
                        }
                    }
                }
            }
        }
    }

    DropArea {
        id: dropArea
        anchors.fill: parent
        enabled: root.dropEnabled && root.isActive

        onEntered: drag => {
            if (drag.hasUrls)
                drag.acceptProposedAction();
        }
        onDropped: drag => {
            if (drag.hasUrls && drag.urls.length > 0)
                root.filesDropped(Array.from(drag.urls));
            drag.acceptProposedAction();
        }

        Rectangle {
            anchors.fill: parent
            radius: Appearance.rounding.normal
            color: Appearance.colors.colPrimaryContainer
            border.color: Appearance.colors.colPrimary
            border.width: Appearance.borderWidth.emphasis
            opacity: dropArea.containsDrag ? 0.85 : 0
            visible: opacity > 0

            Behavior on opacity {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.space50

                MaterialSymbol {
                    Layout.alignment: Qt.AlignHCenter
                    text: "drive_file_move"
                    fill: 1
                    iconSize: Appearance.font.pixelSize.hugeass
                    color: Appearance.colors.colOnPrimaryContainer
                }
                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    text: Translation.tr("Drop to share on phone")
                    font.pixelSize: Appearance.font.pixelSize.small
                    font.weight: Font.DemiBold
                    color: Appearance.colors.colOnPrimaryContainer
                }
            }
        }
    }
}
