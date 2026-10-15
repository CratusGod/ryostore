import "."
import ".."
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

RowLayout {
    id: root

    property string text: ""
    property string description: ""
    property string buttonIcon: ""
    property alias placeholderText: textArea.placeholderText
    property alias value: textArea.text
    property alias textArea: textArea
    property bool filled: true
    property bool showBorder: !filled
    property bool rounded: false
    property real fieldWidth: 220
    property real fieldHeight: 40
    property color colBackground: filled ? Appearance.colors.colLayer1 : "transparent"
    property color colBackgroundFocused: filled ? Appearance.colors.colLayer2 : "transparent"
    property color colBorder: Appearance.colors.colOutlineVariant
    property color colBorderFocused: Appearance.colors.colPrimary
    property color colOnBackground: Appearance.colors.colOnLayer1
    property color colLabel: Appearance.colors.colOnSecondaryContainer
    property real cornerRadius: rounded ? Appearance.rounding.large : Appearance.rounding.small
    property bool password: false
    property bool revealButton: password
    property bool revealed: false
    property bool singleLine: false
    property bool confirmButtonVisible: false
    property string confirmButtonIcon: "check"
    property color colConfirmBackground: Appearance.colors.colPrimaryContainer
    property color colConfirmBackgroundHover: Appearance.colors.colPrimaryContainerHover
    property color colConfirmBackgroundActive: Appearance.colors.colPrimaryContainerActive
    property color colOnConfirmBackground: Appearance.colors.colOnPrimaryContainer
    signal confirmClicked()

    spacing: Appearance.spacing.space150
    Layout.leftMargin: Appearance.spacing.space100
    Layout.rightMargin: Appearance.spacing.space100

    OptionalMaterialSymbol {
        icon: root.buttonIcon
        iconSize: Appearance.font.pixelSize.larger
        opacity: root.enabled ? 1 : 0.4
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0
        StyledText {
            Layout.fillWidth: true
            text: root.text
            color: root.colLabel
            opacity: root.enabled ? 1 : 0.4
        }
        StyledText {
            Layout.fillWidth: true
            visible: root.description.length > 0
            text: root.description
            font.pixelSize: Appearance.font.pixelSize.smaller
            color: Appearance.colors.colSubtext
            wrapMode: Text.Wrap
            opacity: root.enabled ? 1 : 0.4
        }
    }

    RowLayout {
        Layout.alignment: Qt.AlignVCenter
        spacing: Appearance.spacing.space50

        Rectangle {
            id: fieldBg
            Layout.preferredWidth: root.fieldWidth
            Layout.preferredHeight: root.fieldHeight
            Layout.alignment: Qt.AlignVCenter
            radius: root.cornerRadius
            clip: true
            color: textArea.activeFocus ? root.colBackgroundFocused : root.colBackground
            border.width: (hoverHandler.hovered || textArea.activeFocus) ? (textArea.activeFocus ? 2 : 1) : 0
            border.color: textArea.activeFocus ? root.colBorderFocused : root.colBorder

            Behavior on color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on border.color {
                animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
            }
            Behavior on border.width {
                animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
            }

            HoverHandler {
                id: hoverHandler
            }

            TextArea {
                id: textArea
                anchors.fill: parent
                anchors.leftMargin: Appearance.spacing.space150
                anchors.rightMargin: Appearance.spacing.space150
                enabled: root.enabled
                wrapMode: (root.password || root.singleLine) ? TextArea.NoWrap : TextArea.Wrap
                verticalAlignment: TextEdit.AlignVCenter
                selectByMouse: true
                inputMethodHints: root.password ? Qt.ImhSensitiveData : Qt.ImhNone
                placeholderTextColor: Appearance.colors.colSubtext
                color: root.password && !root.revealed ? "transparent" : root.colOnBackground
                selectedTextColor: root.password && !root.revealed ? "transparent" : Appearance.colors.colOnSecondaryContainer
                selectionColor: Appearance.colors.colSecondaryContainer
                renderType: Text.NativeRendering
                background: null
                padding: 0
                font {
                    family: Appearance.font.family.main
                    pixelSize: Appearance.font.pixelSize.small
                    hintingPreference: Font.PreferFullHinting
                    variableAxes: Appearance.font.variableAxes.main
                }

                Component.onCompleted: {
                    for (const child of textArea.children) {
                        if (child instanceof Text)
                            child.textFormat = Text.PlainText;
                    }
                }

                Keys.onReturnPressed: (event) => {
                    if (root.password || root.singleLine) {
                        event.accepted = true;
                        textArea.focus = false;
                    }
                }
                Keys.onEnterPressed: (event) => {
                    if (root.password || root.singleLine) {
                        event.accepted = true;
                        textArea.focus = false;
                    }
                }

                Loader {
                    active: root.password && !root.revealed
                    enabled: false
                    anchors.fill: parent
                    sourceComponent: PasswordChars {
                        charSize: 16
                        length: textArea.text.length
                        selectionStart: textArea.selectionStart
                        selectionEnd: textArea.selectionEnd
                        cursorPosition: textArea.cursorPosition
                        showCursor: textArea.activeFocus
                    }
                }
            }
        }

        RippleButton {
            visible: root.password && root.revealButton
            enabled: root.enabled
            implicitWidth: 30
            implicitHeight: 30
            buttonRadius: Appearance.rounding.full
            colBackground: "transparent"
            colBackgroundHover: Appearance.colors.colPrimaryContainerHover
            colRipple: Appearance.colors.colPrimaryContainerActive
            onClicked: root.revealed = !root.revealed

            contentItem: MaterialSymbol {
                anchors.centerIn: parent
                anchors.horizontalCenterOffset: -2
                iconSize: Appearance.font.pixelSize.larger
                text: root.revealed ? "visibility_off" : "visibility"
                color: Appearance.colors.colOnLayer1
            }
        }
    }
    RippleButton {
        visible: root.confirmButtonVisible
        implicitWidth: 40
        implicitHeight: 40
        Layout.alignment: Qt.AlignVCenter
        buttonRadius: Appearance.rounding.small
        colBackground: root.colConfirmBackground
        colBackgroundHover: root.colConfirmBackgroundHover
        colRipple: root.colConfirmBackgroundActive
        onClicked: root.confirmClicked()

        contentItem: MaterialSymbol {
            anchors.centerIn: parent
            text: root.confirmButtonIcon
            iconSize: Appearance.font.pixelSize.large
            color: root.colOnConfirmBackground
        }
    }
}
