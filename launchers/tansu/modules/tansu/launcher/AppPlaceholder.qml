import QtQuick
import "../../../modules/common"

Item {
    id: root

    property string name: ""
    property real size: 72

    readonly property string letter: {
        const m = /[\p{L}\p{N}]/u.exec(root.name || "")
        return m ? m[0].toUpperCase() : "?"
    }

    readonly property int kind: {
        const s = root.name || ""
        let h = 0
        for (let i = 0; i < s.length; i++)
            h = (h * 31 + s.charCodeAt(i)) | 0
        return Math.abs(h) % Theme.attributeColors.length
    }
    readonly property color ink: Theme.mono ? Theme.colBorder : "#555473"
    readonly property real outline: Math.max(2, root.size * 0.055)

    width: root.size
    height: root.size

    Rectangle {
        x: Math.round(root.size * 0.05)
        y: Math.round(root.size * 0.05)
        width: root.size
        height: root.size
        radius: root.size * 0.30
        color: root.ink
        antialiasing: true
    }

    Rectangle {
        anchors.fill: parent
        radius: root.size * 0.30
        color: Theme.attributeColors[root.kind]
        border.width: root.outline
        border.color: root.ink
        antialiasing: true
    }

    Rectangle {
        x: root.size * 0.17
        y: root.size * 0.13
        width: root.size * 0.30
        height: root.size * 0.13
        radius: height / 2
        rotation: -24
        color: Qt.rgba(1, 1, 1, 0.5)
        antialiasing: true
    }

    Text {
        anchors.centerIn: parent
        text: root.letter
        color: "#ffffff"
        style: Text.Outline
        styleColor: root.ink
        font.family: Theme.fontFamily
        font.pixelSize: Math.round(root.size * 0.5)
        font.weight: Font.ExtraBold
        font.styleName: Theme.fontStyleBold
    }
}
