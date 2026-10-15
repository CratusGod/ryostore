import QtQuick
import ".."
import "../functions"
import "."

ToolbarTextField {
    id: root

    property bool masked: true
    property color colText: Appearance.colors.colOnLayer1
    property int charSize: 20

    property bool materialShapeChars: false

    echoMode: root.masked ? TextInput.Password : TextInput.Normal
    inputMethodHints: root.masked ? Qt.ImhSensitiveData : Qt.ImhNone
    clip: true

    color: ColorUtils.transparentize(root.colText, root.materialShapeChars ? 1 : 0)
    selectedTextColor: root.materialShapeChars ? "transparent" : Appearance.colors.colOnSecondaryContainer
    selectionColor: root.materialShapeChars ? "transparent" : Appearance.colors.colSecondaryContainer

    Loader {
        active: root.materialShapeChars
        enabled: false
        anchors {
            fill: parent
            leftMargin: root.padding
            rightMargin: root.padding
        }
        sourceComponent: PasswordChars {
            charSize: root.charSize
            length: root.text.length
            selectionStart: root.selectionStart
            selectionEnd: root.selectionEnd
            cursorPosition: root.cursorPosition
            showCursor: root.activeFocus
        }
    }
}
