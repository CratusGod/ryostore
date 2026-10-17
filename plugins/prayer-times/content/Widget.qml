import QtQuick
import Ryoku.PluginKit.Singletons

// Prayer-times glyph: crescent mark plus next prayer and countdown.
// Click toggles the panel; a click never mutates anything.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 220

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property string nextName: service ? String(service.nextName) : ""
    readonly property string count: service ? String(service.countdown()) : ""
    readonly property string error: service ? String(service.error) : ""
    readonly property bool stale: service ? service.stale === true : false

    readonly property string labelText: {
        if (root.error !== "") return "prayer?";
        if (root.nextName === "") return "Prayer";
        return root.nextName + " " + root.count;
    }

    implicitWidth: row.implicitWidth + 4 * s
    implicitHeight: Math.max(row.implicitHeight, 18 * s)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6 * root.s

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "☾"
            color: root.stale || root.error !== "" ? Theme.dim : Theme.bright
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.labelText
            color: root.stale || root.error !== "" ? Theme.dim : Theme.bright
            font.family: Theme.font
            font.pixelSize: 13 * root.s
            elide: Text.ElideRight
            width: root.widthBudget > 0 ? Math.min(implicitWidth, root.widthBudget) : implicitWidth
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
