pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Ryoku.Ui.Singletons

Item {
    id: root

    required property string kind
    required property var screen
    property real us: 1
    property bool shown: false
    property real value: 0
    property real maxValue: 1
    property bool muted: false
    property string icon: ""
    property url iconSource: ""
    property string label: ""

    property string placement: "bottom"
    property real reveal: shown ? 1 : 0
    readonly property real fraction: maxValue > 0
        ? Math.max(0, Math.min(1, value / maxValue)) : 0

    implicitWidth: 296 * us
    implicitHeight: 76 * us
    opacity: reveal
    scale: 0.97 + reveal * 0.03
    transform: Translate { y: (1 - root.reveal) * Tokens.s2 * root.us }

    Behavior on reveal {
        NumberAnimation {
            duration: Tokens.dur(140)
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Tokens.radius * root.us
        color: Tokens.paperLift
        border.width: Tokens.border
        border.color: Tokens.line

        RowLayout {
            anchors.fill: parent
            anchors.margins: Tokens.s4 * root.us
            spacing: Tokens.s3 * root.us

            Item {
                Layout.preferredWidth: 30 * root.us
                Layout.preferredHeight: 30 * root.us

                Image {
                    id: sourceGlyph
                    anchors.fill: parent
                    source: root.iconSource
                    fillMode: Image.PreserveAspectFit
                    smooth: true
                    visible: false
                }

                MultiEffect {
                    anchors.fill: sourceGlyph
                    source: sourceGlyph
                    brightness: 1
                    colorization: 1
                    colorizationColor: root.muted ? Tokens.inkMuted : Tokens.sun
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Tokens.s2 * root.us

                Text {
                    Layout.fillWidth: true
                    text: root.label
                    color: root.muted ? Tokens.inkMuted : Tokens.ink
                    font.family: Tokens.ui
                    font.pixelSize: Tokens.fBody * root.us
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 6 * root.us
                    visible: root.kind !== "keyboard"
                    radius: height / 2
                    color: Tokens.lineSoft

                    Rectangle {
                        width: parent.width * root.fraction
                        height: parent.height
                        radius: parent.radius
                        color: root.muted ? Tokens.inkMuted : Tokens.sun

                        Behavior on width {
                            NumberAnimation {
                                duration: Tokens.dur(100)
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
            }
        }
    }
}
