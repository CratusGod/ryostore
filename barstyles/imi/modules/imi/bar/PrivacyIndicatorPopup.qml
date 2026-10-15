import QtQuick
import QtQuick.Layouts
import "../../common"
import "../../common/widgets"
import "../../../services"

StyledPopup {
    id: root
    contentPadding: Appearance.spacing.space150

    readonly property bool expanded: root.pinnedOpen

    readonly property int revealDuration: Appearance.animation.elementMove.duration
    readonly property list<real> revealCurve: Appearance.animationCurves.expressiveDefaultSpatial
    readonly property int fadeDuration: Appearance.animation.elementMoveFast.duration
    readonly property list<real> fadeCurve: Appearance.animationCurves.expressiveEffects

    readonly property real rowIndent: Appearance.font.pixelSize.large + Appearance.spacing.space50

    component ActionSlot: Item {
        id: slot
        property bool on: false
        default property alias content: holder.data
        readonly property real slotSize: 30
        implicitWidth: on ? slotSize : 0
        implicitHeight: slotSize
        opacity: on ? 1 : 0
        scale: on ? 1 : 0.6
        clip: true
        visible: implicitWidth > 0.5
        Behavior on implicitWidth {
            NumberAnimation {
                duration: root.revealDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.revealCurve
            }
        }
        Behavior on opacity {
            NumberAnimation {
                duration: root.fadeDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.fadeCurve
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: root.revealDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.revealCurve
            }
        }
        Item {
            id: holder
            width: slot.slotSize
            height: slot.slotSize
            anchors.centerIn: parent
        }
    }

    component Reveal: Item {
        id: reveal
        property bool shown: false
        default property alias content: revealColumn.data
        Layout.fillWidth: true
        implicitHeight: reveal.shown ? revealColumn.implicitHeight : 0
        clip: true
        visible: implicitHeight > 0.5
        Behavior on implicitHeight {
            NumberAnimation {
                duration: root.revealDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.revealCurve
            }
        }
        ColumnLayout {
            id: revealColumn
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: Appearance.spacing.space25
        }
    }

    component ActionButton: RippleButton {
        id: actionButton
        required property string symbol
        property color symbolColor: Appearance.colors.colOnSurfaceVariant
        anchors.fill: parent
        buttonRadius: Appearance.rounding.full
        MaterialSymbol {
            anchors.centerIn: parent
            text: actionButton.symbol
            iconSize: Appearance.font.pixelSize.normal
            color: actionButton.symbolColor
        }
    }

    component AppRow: RowLayout {
        id: appRow
        required property string name
        property var stream: null
        property string note: ""
        Layout.fillWidth: true
        Layout.leftMargin: root.rowIndent
        spacing: Appearance.spacing.space50

        StyledText {
            Layout.fillWidth: true
            text: appRow.name
            wrapMode: Text.Wrap
            color: Appearance.colors.colOnSurfaceVariant
            opacity: appRow.stream?.muted ? 0.55 : 0.75
            font.pixelSize: Appearance.font.pixelSize.smaller
            Behavior on opacity {
                NumberAnimation {
                    duration: root.fadeDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.fadeCurve
                }
            }
        }

        StyledText {
            visible: opacity > 0.01
            opacity: (root.expanded && appRow.note.length > 0 && appRow.stream === null) ? 0.5 : 0
            text: appRow.note
            color: Appearance.colors.colOnSurfaceVariant
            font.pixelSize: Appearance.font.pixelSize.smallest
            Behavior on opacity {
                NumberAnimation {
                    duration: root.fadeDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: root.fadeCurve
                }
            }
        }

        ActionSlot {
            on: root.expanded && appRow.stream !== null
            ActionButton {
                symbol: appRow.stream?.muted ? "mic_off" : "mic"
                symbolColor: appRow.stream?.muted
                    ? Appearance.colors.colPrimary
                    : Appearance.colors.colOnSurfaceVariant
                toggled: appRow.stream?.muted ?? false
                releaseAction: () => CaptureControl.toggleStreamMuted(appRow.stream)
            }
        }

        ActionSlot {
            on: root.expanded && appRow.stream !== null && CaptureControl.allowForceStop
            ActionButton {
                symbol: "block"
                symbolColor: Appearance.colors.colError
                releaseAction: () => CaptureControl.forceStopStream(appRow.stream)
            }
        }
    }

    component DeviceSection: ColumnLayout {
        id: section
        required property string icon
        required property string label
        property var entries: []
        property var streams: []
        property string rowNote: ""
        Layout.fillWidth: true
        spacing: Appearance.spacing.space25

        RowLayout {
            Layout.fillWidth: true
            spacing: Appearance.spacing.space50
            MaterialSymbol {
                text: section.icon
                iconSize: Appearance.font.pixelSize.large
                color: Appearance.colors.colOnSurfaceVariant
            }
            StyledText {
                Layout.fillWidth: true
                text: section.label
                font.weight: Font.Medium
                color: Appearance.colors.colOnSurfaceVariant
            }
        }

        Repeater {
            model: section.streams.length > 0 ? section.streams : section.entries
            delegate: AppRow {
                required property var modelData
                name: (modelData && modelData.name !== undefined) ? modelData.name : String(modelData)
                stream: (modelData && modelData.name !== undefined) ? modelData : null
                note: section.rowNote
            }
        }
    }

    Item {
        id: contentRoot
        implicitWidth: root.expanded ? 340 : 260
        implicitHeight: column.implicitHeight

        Behavior on implicitWidth {
            NumberAnimation {
                duration: root.revealDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.revealCurve
            }
        }

        ColumnLayout {
            id: column
            anchors { left: parent.left; right: parent.right; top: parent.top }
            spacing: Appearance.spacing.space100

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Appearance.spacing.space50
                StyledText {
                    Layout.fillWidth: true
                    text: Translation.tr("Privacy")
                    font.pixelSize: Appearance.font.pixelSize.normal
                    font.weight: Font.Medium
                    color: Appearance.colors.colError
                }
                StyledText {
                    visible: opacity > 0.01
                    opacity: root.expanded ? 0 : 0.5
                    text: Translation.tr("Click for controls")
                    font.pixelSize: Appearance.font.pixelSize.smallest
                    color: Appearance.colors.colOnSurfaceVariant
                    Behavior on opacity {
                        NumberAnimation {
                            duration: root.fadeDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: root.fadeCurve
                        }
                    }
                }
            }

            DeviceSection {
                visible: MediaCapture.micActive
                icon: "mic"
                label: Translation.tr("Microphone")
                streams: MediaCapture.micStreams
                entries: MediaCapture.micApps.length > 0
                    ? MediaCapture.micApps
                    : [Translation.tr("In use")]
            }

            DeviceSection {
                visible: MediaCapture.cameraActive
                icon: "videocam"
                label: Translation.tr("Camera")
                entries: MediaCapture.cameraApps.length > 0
                    ? MediaCapture.cameraApps
                    : [Translation.tr("In use")]
                rowNote: Translation.tr("no stream control")
            }

            DeviceSection {
                visible: MediaCapture.screencastActive
                icon: "screen_share"
                label: Translation.tr("Screen")
                entries: [Translation.tr("Shared or recorded")]
                rowNote: Translation.tr("stop it from that app")
            }

            ColumnLayout {
                visible: ScreenRecord.recording || ScreenRecord.replaying
                Layout.fillWidth: true
                spacing: Appearance.spacing.space25

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.space50
                    MaterialSymbol {
                        text: ScreenRecord.recording ? "screen_record" : "replay"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: ScreenRecord.recording
                            ? Translation.tr("Recording")
                            : Translation.tr("Instant replay")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: root.rowIndent
                    spacing: Appearance.spacing.space50

                    StyledText {
                        Layout.fillWidth: true
                        text: ScreenRecord.recording
                            ? (ScreenRecord.recordPaused ? Translation.tr("Paused") : Translation.tr("Recording the screen"))
                            : Translation.tr("Buffering the last moments")
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.75
                        font.pixelSize: Appearance.font.pixelSize.smaller
                    }

                    ActionSlot {
                        on: root.expanded && ScreenRecord.recording
                        ActionButton {
                            symbol: ScreenRecord.recordPaused ? "play_arrow" : "pause"
                            releaseAction: () => ScreenRecord.togglePauseRecord()
                        }
                    }
                    ActionSlot {
                        on: root.expanded && ScreenRecord.recording
                        ActionButton {
                            symbol: "stop"
                            symbolColor: Appearance.colors.colError
                            releaseAction: () => ScreenRecord.stopRecord()
                        }
                    }
                    ActionSlot {
                        on: root.expanded && ScreenRecord.replaying
                        ActionButton {
                            symbol: "save"
                            symbolColor: Appearance.colors.colPrimary
                            releaseAction: () => ScreenRecord.saveReplay()
                        }
                    }
                    ActionSlot {
                        on: root.expanded && ScreenRecord.replaying
                        ActionButton {
                            symbol: "stop"
                            symbolColor: Appearance.colors.colError
                            releaseAction: () => ScreenRecord.toggleReplay()
                        }
                    }
                }
            }

            Reveal {
                shown: root.expanded

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.space50
                    MaterialSymbol {
                        text: "key"
                        iconSize: Appearance.font.pixelSize.large
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                    StyledText {
                        Layout.fillWidth: true
                        text: Translation.tr("Granted permissions")
                        font.weight: Font.Medium
                        color: Appearance.colors.colOnSurfaceVariant
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.space25

                    Repeater {
                        model: CaptureControl.permissions
                        delegate: ColumnLayout {
                            id: permissionEntry
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 0
                            visible: permissionEntry.modelData.apps.length > 0

                            Repeater {
                                model: permissionEntry.modelData.apps
                                delegate: RowLayout {
                                    id: permissionAppRow
                                    required property var modelData
                                    Layout.fillWidth: true
                                    Layout.leftMargin: root.rowIndent
                                    spacing: Appearance.spacing.space50

                                    StyledText {
                                        Layout.fillWidth: true
                                        text: permissionAppRow.modelData.app
                                        wrapMode: Text.Wrap
                                        elide: Text.ElideMiddle
                                        color: Appearance.colors.colOnSurfaceVariant
                                        opacity: 0.75
                                        font.pixelSize: Appearance.font.pixelSize.smaller
                                    }
                                    ActionSlot {
                                        on: root.expanded
                                        ActionButton {
                                            symbol: "block"
                                            symbolColor: Appearance.colors.colError
                                            releaseAction: () => CaptureControl.revokePermission(
                                                permissionEntry.modelData.id, permissionAppRow.modelData.app)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    StyledText {
                        visible: CaptureControl.permissions.every(p => p.apps.length === 0)
                        Layout.fillWidth: true
                        Layout.leftMargin: root.rowIndent
                        text: Translation.tr("Nothing granted through the desktop portal. Apps that open the device directly do not appear here.")
                        wrapMode: Text.Wrap
                        color: Appearance.colors.colOnSurfaceVariant
                        opacity: 0.55
                        font.pixelSize: Appearance.font.pixelSize.smallest
                    }
                }
            }
        }
    }

    onExpandedChanged: {
        if (root.expanded) CaptureControl.refreshPermissions();
        root.contentDrivesSize = true;
        depthSettle.restart();
    }

    property Timer depthSettle: Timer {
        interval: root.revealDuration + 60
        onTriggered: root.contentDrivesSize = false
    }
}
