import QtQuick
import Ryoku.PluginKit.Singletons

// The panel: one switch. Mode and battery floor
// live in QS Bar Settings > Community.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 260
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property bool on: service ? service.on : false
    readonly property bool busy: service ? service.busy : false
    readonly property string note: !service ? ""
        : service.error !== "" ? service.error
        : !on && service.reason !== "" ? service.reason
        : ""

    implicitWidth: root.widthBudget
    implicitHeight: col.implicitHeight + 24 * root.s

    onActiveChanged: if (active && service) service.refresh()

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.width - 24 * root.s
        spacing: 12 * root.s

        Row {
            spacing: 10 * root.s
            CoffeeCup {
                anchors.verticalCenter: parent.verticalCenter
                width: 26 * root.s
                height: 26 * root.s
                steaming: root.on && root.active
                color: root.on ? Theme.accent : Theme.dim
            }
            Column {
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: "Caffeinated"
                    color: Theme.bright
                    font.family: Theme.display
                    font.pixelSize: 16 * root.s
                }
                Text {
                    text: root.on ? "On: the machine will not sleep" : "Off"
                    color: Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 12 * root.s
                }
            }
        }

        Text {
            width: parent.width
            visible: root.note !== ""
            wrapMode: Text.WordWrap
            text: root.note
            color: root.service && root.service.error !== "" ? Theme.sun : Theme.gold
            font.family: Theme.font
            font.pixelSize: 12 * root.s
        }

        Rectangle {
            width: parent.width
            height: label.implicitHeight + 16 * root.s
            radius: Theme.radius
            opacity: root.busy ? 0.6 : 1
            color: root.on ? (area.pressed ? Theme.hair : Theme.tileBg)
                           : (area.pressed ? Theme.vermDeep : Theme.accent)
            border.color: root.on ? Theme.border : "transparent"
            border.width: 1

            Text {
                id: label
                anchors.centerIn: parent
                text: root.busy ? "…" : root.on ? "TURN OFF" : "TURN ON"
                color: root.on ? Theme.bright : Theme.cardBot
                font.family: Theme.font
                font.pixelSize: 13 * root.s
            }

            MouseArea {
                id: area
                anchors.fill: parent
                enabled: !root.busy
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (!root.service) return;
                    // Turning on may lock the screen; get the panel out of the way first.
                    if (!root.on && root.pluginApi) root.pluginApi.closePanel();
                    root.service.toggle();
                }
            }
        }
    }
}
