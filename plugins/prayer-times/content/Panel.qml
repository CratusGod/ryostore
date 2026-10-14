import QtQuick
import Ryoku.PluginKit.Singletons

// Prayer-times panel: today's six times with the next one highlighted,
// Gregorian + Hijri dates, and a manual refresh on an explicit click.
Item {
    id: root

    property var pluginApi
    property string density: "full"
    property real s: 1
    property real widthBudget: 320
    property bool active: false

    readonly property var service: pluginApi ? pluginApi.mainInstance : null
    readonly property var timings: service ? service.timings : ({})
    readonly property var order: service ? service.order : []
    readonly property string nextName: service ? String(service.nextName) : ""
    readonly property string gregDate: service ? String(service.gregDate) : ""
    readonly property string hijriDate: service ? String(service.hijriDate) : ""
    readonly property string city: service ? String(service.city) : ""
    readonly property string country: service ? String(service.country) : ""
    readonly property bool stale: service ? service.stale === true : false
    readonly property string error: service ? String(service.error) : ""

    onActiveChanged: if (active && root.service) root.service.refresh()

    implicitWidth: widthBudget
    implicitHeight: col.implicitHeight + 24 * s

    Column {
        id: col
        x: 12 * root.s
        y: 12 * root.s
        width: root.widthBudget - 24 * root.s
        spacing: 8 * root.s

        Text {
            text: "Prayer Times"
            color: Theme.bright
            font.family: Theme.display
            font.pixelSize: 16 * root.s
        }
        Text {
            text: (root.city !== "" ? root.city + ", " + root.country : "")
                  + (root.gregDate !== "" ? " · " + root.gregDate : "")
                  + (root.hijriDate !== "" ? "\n" + root.hijriDate + " Hijri" : "")
                  + (root.stale ? "\n(offline — showing cached times)" : "")
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            wrapMode: Text.Wrap
            width: parent.width
        }

        Text {
            visible: root.error !== ""
            text: root.error
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 12 * root.s
            wrapMode: Text.Wrap
            width: parent.width
        }

        Repeater {
            model: root.order
            Row {
                width: parent.width
                spacing: 8 * root.s
                visible: root.timings[modelData] !== undefined
                Text {
                    text: modelData
                    color: root.nextName === modelData ? Theme.accent : Theme.dim
                    font.family: Theme.font
                    font.pixelSize: 13 * root.s
                    width: parent.width * 0.45
                }
                Text {
                    text: root.service ? root.service.fmtTime(root.timings[modelData]) : ""
                    color: root.nextName === modelData ? Theme.bright : Theme.dim
                    font.family: Theme.mono
                    font.pixelSize: 13 * root.s
                }
            }
        }

        Rectangle {
            width: rLabel.implicitWidth + 18 * root.s
            height: rLabel.implicitHeight + 10 * root.s
            color: "transparent"
            border.width: 1
            border.color: Theme.border
            Text {
                id: rLabel
                anchors.centerIn: parent
                text: "Refresh"
                color: Theme.dim
                font.family: Theme.font
                font.pixelSize: 11 * root.s
            }
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: if (root.service) root.service.refresh()
            }
        }

        Text {
            text: "City, method and time format live under QS Bar Settings > Community > Prayer Times."
            color: Theme.dim
            font.family: Theme.font
            font.pixelSize: 11 * root.s
            wrapMode: Text.Wrap
            width: parent.width
        }
    }
}
