import QtQuick
import Ryoku.PluginKit.Singletons

// The bar glyph: a keyboard and the layout code of the keyboard in use (US,
// GB, DE...). Accent while a plugged-in keyboard has a layout chosen here, dim
// otherwise. A click only opens the panel.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property string code: service && service.current !== "" ? service.current : "--"
    readonly property bool managed: {
        if (!service) return false;
        for (const k of service.keyboards)
            if (service.assigned[k.name]) return true;
        return false;
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 5 * root.s

        KeyboardIcon {
            anchors.verticalCenter: parent.verticalCenter
            width: 21 * root.s
            height: 14 * root.s
            stroke: 1.7
            color: root.managed ? Theme.accent : Theme.dim
            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.code.toUpperCase()
            color: root.managed ? Theme.accent : Theme.bright
            font.family: Theme.mono
            font.weight: Font.DemiBold
            font.pixelSize: 11 * root.s
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
