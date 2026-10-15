import ".."
import QtQuick

QtObject {
    id: root

    property bool hovered: false
    property bool down: false
    property bool controlEnabled: true

    readonly property string interactionState: Appearance.interaction.state({
        hovered: root.hovered, down: root.down, enabled: root.controlEnabled
    })
    property string previousState: root.interactionState

    property real scale: 1
    property real radiusScale: 1
    property real hoverProgress: 0
    property real pressProgress: 0
    property real dimOpacity: 1

    onInteractionStateChanged: {
        const transition = Appearance.interaction.transition(root.previousState, root.interactionState);
        root.previousState = root.interactionState;
        scaleAnim.duration = transition.duration;
        scaleAnim.easing.bezierCurve = transition.curve;
        radiusAnim.duration = transition.duration;
        radiusAnim.easing.bezierCurve = transition.curve;
        hoverAnim.duration = transition.duration;
        hoverAnim.easing.bezierCurve = transition.curve;
        pressAnim.duration = transition.duration;
        pressAnim.easing.bezierCurve = transition.curve;
        opacityAnim.duration = transition.duration;
        opacityAnim.easing.bezierCurve = transition.curve;
        root.applyTargets();
    }

    function applyTargets() {
        const targets = Appearance.interaction.targets(root.interactionState);
        root.scale = targets.scale;
        root.radiusScale = targets.radiusScale;
        root.hoverProgress = targets.hover;
        root.pressProgress = targets.press;
        root.dimOpacity = targets.opacity;
    }

    Behavior on scale {
        NumberAnimation { id: scaleAnim; easing.type: Easing.BezierSpline }
    }
    Behavior on radiusScale {
        NumberAnimation { id: radiusAnim; easing.type: Easing.BezierSpline }
    }
    Behavior on hoverProgress {
        NumberAnimation { id: hoverAnim; easing.type: Easing.BezierSpline }
    }
    Behavior on pressProgress {
        NumberAnimation { id: pressAnim; easing.type: Easing.BezierSpline }
    }
    Behavior on dimOpacity {
        NumberAnimation { id: opacityAnim; easing.type: Easing.BezierSpline }
    }

    Component.onCompleted: root.applyTargets()
}
