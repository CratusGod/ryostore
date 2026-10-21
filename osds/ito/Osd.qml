import QtQuick
import QtQuick.Effects
import shell.services
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

    property string placement: kind === "keyboard" ? "top" : "right"
    property real reveal: shown ? 1 : 0

    readonly property bool keyboardMode: kind === "keyboard"
    readonly property real safeMaximum: maxValue > 0 ? maxValue : 1
    readonly property real baseRatio: Math.max(0, Math.min(value, 1)) / safeMaximum
    readonly property real overflowRatio: Math.max(0, Math.min(value, safeMaximum) - 1) / safeMaximum
    readonly property real trackHeight: (Tokens.s7 * 3 + Tokens.s5 + Tokens.s3) * us

    implicitWidth: (keyboardMode ? Tokens.s7 * 4 + Tokens.s2 : Tokens.s7 + Tokens.s2) * us
    implicitHeight: (keyboardMode ? Tokens.rowH : Tokens.s7 * 5 + Tokens.s5) * us

    Behavior on reveal {
        NumberAnimation {
            duration: Tokens.reduceMotion ? 0 : Motion.fast
            easing.type: Tokens.ease
        }
    }

    component InkGlyph: Item {
        id: glyphRoot

        required property url sourceUrl
        property color tint: Tokens.ink
        property bool struck: false

        Image {
            id: glyphImage
            anchors.fill: parent
            source: glyphRoot.sourceUrl
            sourceSize.width: Math.ceil(width)
            sourceSize.height: Math.ceil(height)
            fillMode: Image.PreserveAspectFit
            smooth: true
            mipmap: true
            visible: false
        }

        MultiEffect {
            anchors.fill: parent
            source: glyphImage
            brightness: 1.0
            colorization: 1
            colorizationColor: glyphRoot.tint
        }

        Rectangle {
            anchors.centerIn: parent
            width: parent.width + Tokens.s1 * root.us
            height: Math.max(Tokens.border, Tokens.border * root.us)
            color: Tokens.inkDim
            rotation: -12
            visible: glyphRoot.struck
        }
    }

    Item {
        id: animatedFace
        width: root.width
        height: root.height
        x: root.keyboardMode ? 0 : (1 - root.reveal) * Tokens.s3 * root.us
        y: root.keyboardMode ? -(1 - root.reveal) * Tokens.s3 * root.us : 0
        opacity: root.reveal

        Rectangle {
            id: threadPlate
            anchors.centerIn: parent
            width: Tokens.s7 * root.us
            height: parent.height - Tokens.s3 * root.us
            radius: Tokens.radius * root.us
            color: Tokens.paperLift
            border.width: Math.max(Tokens.border, Tokens.border * root.us)
            border.color: Tokens.line
            visible: !root.keyboardMode

            Column {
                width: parent.width
                spacing: Tokens.s2 * root.us
                anchors.centerIn: parent

                InkGlyph {
                    width: (Tokens.s5 - Tokens.s1) * root.us
                    height: width
                    anchors.horizontalCenter: parent.horizontalCenter
                    sourceUrl: root.iconSource
                    tint: root.muted ? Tokens.inkFaint : Tokens.ink
                    struck: root.muted
                }

                Item {
                    id: threadTrack
                    width: Tokens.s1 * root.us
                    height: root.trackHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        color: Tokens.lineSoft
                        border.width: Math.max(Tokens.border, Tokens.border * root.us)
                        border.color: Tokens.lineStrong
                    }

                    Rectangle {
                        id: baseFill
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: parent.width
                        height: parent.height * root.baseRatio
                        color: Tokens.sun
                        opacity: root.muted ? 0.28 : 1

                        Behavior on height {
                            NumberAnimation {
                                duration: Tokens.reduceMotion ? 0 : Motion.fast
                                easing.type: Tokens.ease
                            }
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: baseFill.top
                        width: parent.width
                        height: parent.height * root.overflowRatio
                        color: Tokens.alert
                        opacity: root.muted ? 0.28 : 1

                        Behavior on height {
                            NumberAnimation {
                                duration: Tokens.reduceMotion ? 0 : Motion.fast
                                easing.type: Tokens.ease
                            }
                        }
                    }

                    Repeater {
                        model: root.muted ? 18 : 0

                        delegate: Rectangle {
                            required property int index
                            x: 0
                            y: (index * 10 + 6) * root.us
                            width: threadTrack.width
                            height: Tokens.s1 * root.us
                            color: Tokens.paperLift
                        }
                    }
                }

                Text {
                    width: parent.width - Tokens.s2 * root.us
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.label
                    color: root.muted ? Tokens.inkFaint : Tokens.inkDim
                    font.family: Tokens.mono
                    font.pixelSize: Tokens.fMicro * root.us
                    font.letterSpacing: Tokens.trackLabel * root.us
                    font.capitalization: Font.AllUppercase
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                }
            }
        }

        Rectangle {
            id: keyboardTag
            anchors.centerIn: parent
            width: parent.width
            height: parent.height
            radius: Tokens.radius * root.us
            color: Tokens.paperLift
            border.width: Math.max(Tokens.border, Tokens.border * root.us)
            border.color: Tokens.line
            visible: root.keyboardMode

            InkGlyph {
                id: keyboardGlyph
                width: (Tokens.s5 - Tokens.s1) * root.us
                height: width
                anchors.left: parent.left
                anchors.leftMargin: Tokens.s3 * root.us
                anchors.verticalCenter: parent.verticalCenter
                sourceUrl: root.iconSource
                tint: Tokens.ink
            }

            Rectangle {
                anchors.left: keyboardGlyph.right
                anchors.leftMargin: Tokens.s3 * root.us
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(Tokens.border, Tokens.border * root.us)
                height: parent.height - Tokens.s4 * root.us
                color: Tokens.lineStrong
            }

            Text {
                anchors.left: keyboardGlyph.right
                anchors.leftMargin: (Tokens.s3 * 2 + Tokens.border) * root.us
                anchors.right: parent.right
                anchors.rightMargin: Tokens.s3 * root.us
                anchors.verticalCenter: parent.verticalCenter
                text: root.label
                color: Tokens.ink
                font.family: Tokens.mono
                font.pixelSize: Tokens.fSmall * root.us
                font.letterSpacing: Tokens.trackLabel * root.us
                font.capitalization: Font.AllUppercase
                elide: Text.ElideRight
            }
        }
    }
}
