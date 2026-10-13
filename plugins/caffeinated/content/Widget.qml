import QtQuick
import Ryoku.PluginKit.Singletons

// The bar glyph: a coffee cup, steaming in the accent while Caffeinated holds
// the machine awake, a plain cup when off. A click only opens the panel.
Item {
    id: root

    property var pluginApi
    property var screen
    property bool active: false
    property string density: "glyph"
    property real s: 1
    property real widthBudget: 0

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool on: service ? service.on : false

    implicitWidth: cup.width
    implicitHeight: Math.max(cup.height, 18 * root.s)

    CoffeeCup {
        id: cup
        anchors.centerIn: parent
        width: 18 * root.s
        height: 18 * root.s
        steaming: root.on && root.active
        color: root.on ? Theme.accent : Theme.dim
        Behavior on color { ColorAnimation { duration: 150 } }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: if (root.pluginApi) root.pluginApi.togglePanel()
    }
}
