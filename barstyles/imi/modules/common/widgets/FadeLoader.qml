import QtQuick

import ".."

Loader {
    id: root
    property bool shown: true
    property alias fade: opacityBehavior.enabled

    property int enterDuration: Appearance.animation.elementMoveFast.duration
    property var enterEasingCurve: Appearance.animation.elementMoveFast.bezierCurve
    property int exitDuration: Appearance.animation.elementMoveFast.duration
    property var exitEasingCurve: Appearance.animation.elementMoveFast.bezierCurve

    opacity: shown ? 1 : 0
    visible: opacity > 0
    active: opacity > 0

    Behavior on opacity {
        id: opacityBehavior
        NumberAnimation {
            duration: root.shown ? root.enterDuration : root.exitDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: root.shown ? root.enterEasingCurve : root.exitEasingCurve
        }
    }
}
