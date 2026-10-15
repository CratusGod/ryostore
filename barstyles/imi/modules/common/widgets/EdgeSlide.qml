import QtQuick
import ".."

QtObject {
    id: root

    required property bool open

    required property real travel

    property int direction: 1

    property real progress: 0

    readonly property real offset: (1 - root.progress) * root.travel * root.direction

    readonly property real reveal: root.progress >= 1 ? 1
        : root.progress <= 0 ? 0
        : root.progress < 0.4 ? 0.15 * (root.progress / 0.4)
        : 0.15 + 0.85 * ((root.progress - 0.4) / 0.6)

    readonly property bool shown: root.open || root.progress > 0

    onOpenChanged: {
        if (root.open)
            root.arrive();
        else
            root.leave();
    }

    Component.onCompleted: {
        if (root.open)
            root.progress = 1;
    }

    function arrive() {
        root.exitAnim.stop();
        root.enterAnim.start();
    }

    function leave() {
        root.enterAnim.stop();
        root.exitAnim.start();
    }

    readonly property NumberAnimation enterAnim: NumberAnimation {
        target: root
        property: "progress"
        to: 1
        duration: Appearance.animation.sidebarSlideEnter.duration
        easing.type: Appearance.animation.sidebarSlideEnter.type
        easing.bezierCurve: Appearance.animation.sidebarSlideEnter.bezierCurve
    }

    readonly property NumberAnimation exitAnim: NumberAnimation {
        target: root
        property: "progress"
        to: 0
        duration: Appearance.animation.sidebarSlideExit.duration
        easing.type: Appearance.animation.sidebarSlideExit.type
        easing.bezierCurve: Appearance.animation.sidebarSlideExit.bezierCurve
    }
}
