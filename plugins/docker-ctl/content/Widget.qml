pragma ComponentBehavior: Bound
import QtQuick
import Ryoku.PluginKit.Singletons

// The bar glyph: the Docker whale, tinted while the daemon runs, with the
// running-container count beside it. A click opens the panel; nothing here
// ever acts on Docker.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0
    property bool open: false
    property real reveal: 0
    property bool tabActive: false
    signal requestClose()

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool up: service ? service.daemon === "active" : false
    readonly property int count: service ? service.runningCount : 0
    readonly property bool showCount: pluginApi ? (pluginApi.pluginSettings.showCount ?? true) : true

    implicitWidth: row.implicitWidth
    implicitHeight: Math.max(row.implicitHeight, 18 * root.s)

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 5 * root.s

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: ""
            color: root.up ? Theme.accent : Theme.dim
            opacity: root.up ? 1 : 0.6
            font.family: Theme.mono
            font.pixelSize: 15 * root.s
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.showCount && root.up
            text: root.count
            color: Theme.bright
            font.family: Theme.font
            font.pixelSize: 13 * root.s
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (!root.pluginApi)
                return;
            if (root.open)
                root.requestClose();
            else if (root.pluginApi.togglePanel)
                root.pluginApi.togglePanel();
        }
    }
}
