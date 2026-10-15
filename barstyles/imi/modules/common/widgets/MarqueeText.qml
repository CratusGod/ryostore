import ".."
import "../functions/marquee.js" as Marquee
import QtQuick

Item {
    id: root

    property alias text: label.text
    property alias color: label.color
    property alias font: label.font
    property int horizontalAlignment: Text.AlignLeft

    readonly property bool overflows: Marquee.overflows(label.implicitWidth, root.width)
    readonly property real travelDistance: Marquee.travelDistance(label.implicitWidth, root.width)

    readonly property bool scrolling: root.overflows && root.visible

    implicitWidth: label.implicitWidth
    implicitHeight: label.implicitHeight
    clip: true

    onScrollingChanged: if (!root.scrolling) label.x = 0

    StyledText {
        id: label

        width: root.width
        height: root.height
        x: 0
        elide: Text.ElideNone
        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: root.overflows ? Text.AlignLeft : root.horizontalAlignment
    }

    SequentialAnimation {
        running: root.scrolling
        loops: Animation.Infinite

        PauseAnimation { duration: Marquee.dwell(Appearance.animation.reduceMotion) }
        MarqueeTravel { to: -root.travelDistance }
        PauseAnimation { duration: Marquee.dwell(Appearance.animation.reduceMotion) }
        MarqueeTravel { to: 0 }
    }

    component MarqueeTravel: NumberAnimation {
        target: label
        property: "x"
        duration: Appearance.animation.scale(
            Marquee.travelDuration(label.implicitWidth, root.width))
        easing.type: Easing.Linear
    }
}
