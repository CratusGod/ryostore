pragma ComponentBehavior: Bound

import ".."
import "../../../services"
import QtQuick
import QtQuick.Layouts
import shell.services as RyokuServices

Item {
    id: root

    property var player: null

    property color textColor: "white"
    property color activeColor: "white"
    property color dimColor: Qt.rgba(1, 1, 1, 0.35)
    property color indicatorColor: Appearance.colors.colPrimaryContainer
    property color indicatorShapeColor: Appearance.colors.colOnPrimaryContainer
    property int textAlignment: Text.AlignLeft
    property real sidePadding: Appearance.spacing.space300

    readonly property var lines: RyokuServices.Music.lines
    readonly property int activeIndex: RyokuServices.Music.index
    readonly property bool synced: RyokuServices.Music.synced
    readonly property bool unsynced: RyokuServices.Music.unsynced
    readonly property string status: RyokuServices.Music.status

    implicitWidth: 200
    implicitHeight: 200

    readonly property bool wanted: root.visible
    onWantedChanged: RyokuServices.Music.hold(root, root.wanted)
    Component.onCompleted: RyokuServices.Music.hold(root, root.wanted)
    Component.onDestruction: RyokuServices.Music.hold(root, false)

    ColumnLayout {
        anchors.fill: parent
        spacing: Appearance.spacing.space50

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.synced && !root.unsynced

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Appearance.spacing.space150

                MaterialLoadingIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    loading: root.status === "loading"
                    colBg: root.indicatorColor
                    colShape: root.indicatorShapeColor
                    implicitSize: 48
                }

                StyledText {
                    Layout.alignment: Qt.AlignHCenter
                    visible: root.status !== "loading"
                    horizontalAlignment: Text.AlignHCenter
                    text: root.status === "error" ? Translation.tr("Lyrics unavailable")
                        : Translation.tr("No lyrics for this track")
                    font.pixelSize: Appearance.font.pixelSize.small
                    color: root.dimColor
                }
            }
        }

        ListView {
            id: lyricsList
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.synced
            clip: true
            interactive: false
            spacing: Appearance.spacing.space100

            model: root.lines
            currentIndex: root.activeIndex
            highlightFollowsCurrentItem: true
            highlightRangeMode: ListView.StrictlyEnforceRange
            preferredHighlightBegin: Math.max(0, height / 2 - 40)
            preferredHighlightEnd: height / 2 + 40
            highlightMoveDuration: 320
            highlightMoveVelocity: -1
            highlightResizeDuration: 320

            delegate: Item {
                id: lyricSlot
                required property var modelData
                required property int index
                width: lyricsList.width
                implicitHeight: slotText.implicitHeight + Appearance.spacing.space50

                readonly property int dist: Math.abs(index - root.activeIndex)
                readonly property bool isActive: index === root.activeIndex

                scale: isActive ? 1 : 0.94
                transformOrigin: Item.Center
                Behavior on scale {
                    animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                }
                opacity: {
                    if (isActive) return 1.0;
                    if (dist === 1) return 0.6;
                    if (dist === 2) return 0.35;
                    if (dist === 3) return 0.15;
                    return 0.05;
                }
                Behavior on opacity { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }

                MouseArea {
                    anchors.fill: parent
                    enabled: RyokuServices.Music.player?.canSeek ?? false
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                    onClicked: RyokuServices.Music.seek(lyricSlot.modelData.t)
                }

                StyledText {
                    id: slotText
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.leftMargin: root.sidePadding
                    anchors.rightMargin: root.sidePadding
                    horizontalAlignment: root.textAlignment
                    wrapMode: Text.WordWrap
                    text: lyricSlot.modelData.text ?? ""
                    font.pixelSize: lyricSlot.isActive
                        ? Appearance.font.pixelSize.larger
                        : (lyricSlot.dist === 1 ? Appearance.font.pixelSize.large : Appearance.font.pixelSize.normal)
                    Behavior on font.pixelSize { NumberAnimation { duration: 320; easing.type: Easing.OutCubic } }
                    font.weight: lyricSlot.isActive ? Font.Bold : Font.Normal
                    color: lyricSlot.isActive ? root.activeColor : root.textColor
                    Behavior on color { ColorAnimation { duration: 320; easing.type: Easing.OutCubic } }
                }
            }
        }

        Flickable {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.unsynced
            contentHeight: plainColumn.implicitHeight
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Column {
                id: plainColumn
                width: parent.width
                spacing: Appearance.spacing.space50

                Repeater {
                    model: root.unsynced ? RyokuServices.Music.plain : []

                    delegate: StyledText {
                        required property var modelData
                        width: plainColumn.width
                        horizontalAlignment: root.textAlignment
                        wrapMode: Text.WordWrap
                        text: modelData
                        color: root.dimColor
                        font.pixelSize: Appearance.font.pixelSize.small
                    }
                }
            }
        }
    }
}