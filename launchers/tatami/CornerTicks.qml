import QtQuick

// Registration marks: a short L at each corner of the parent, the way a print
// sheet marks where its plate sits. Tatami marks the chosen tile with them.
Item {
    id: ticks

    property color color: "white"
    property real arm: 12
    property real weight: 1

    Repeater {
        model: 4
        delegate: Item {
            id: corner
            required property int index
            readonly property bool east: corner.index % 2 === 1
            readonly property bool south: corner.index >= 2
            width: ticks.arm
            height: ticks.arm
            x: corner.east ? ticks.width - width : 0
            y: corner.south ? ticks.height - height : 0

            Rectangle {
                width: ticks.arm
                height: ticks.weight
                y: corner.south ? ticks.arm - ticks.weight : 0
                color: ticks.color
            }
            Rectangle {
                width: ticks.weight
                height: ticks.arm
                x: corner.east ? ticks.arm - ticks.weight : 0
                color: ticks.color
            }
        }
    }
}
