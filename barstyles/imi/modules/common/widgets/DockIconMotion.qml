import QtQuick
import ".."
import "."
import "../../imi/dock/dock_geometry.js" as DockGeometry

Item {
    id: root

    property bool hovered: false
    property bool pressed: false
    property bool launching: false
    property bool dragging: false

    readonly property string dockEdge: DockGeometry.normalizedEdge(
        Config.options?.dock.edge ?? "bottom")
    readonly property var liftVector: DockGeometry.inwardVector(root.dockEdge)

    property real hoverScale: 1.15
    property real pressScale: 0.92

    default property alias content: contentContainer.data

    readonly property InteractionMotion motion: InteractionMotion {
        hovered: root.hovered && !root.dragging
        down: root.pressed && !root.dragging
    }
    readonly property real targetScale: root.dragging
        ? 1.0
        : 1 + (root.hoverScale - 1) * root.motion.hoverProgress
            + (root.pressScale - 1) * root.motion.pressProgress

    Component.onDestruction: {
        bounceAnimation.stop();
        appearAnimation.stop();
    }

    property real liftOffset: (!dragging && hovered && !pressed) ? Appearance.spacing.space50 : 0
    Behavior on liftOffset {
        NumberAnimation {
            duration: Appearance.animation.elementMoveSmall.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveFastSpatial
        }
    }

    property real bounceOffset: 0
    SequentialAnimation {
        id: bounceAnimation
        running: root.launching && !root.dragging && root.visible
        loops: Animation.Infinite
        alwaysRunToEnd: true
        NumberAnimation {
            target: root
            property: "bounceOffset"
            to: Appearance.spacing.space100
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        NumberAnimation {
            target: root
            property: "bounceOffset"
            to: 0
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
        PauseAnimation {
            duration: Appearance.animation.elementMoveFast.duration
        }
    }

    property real appearScale: 1
    property real appearOpacity: 1
    function playAppear() {
        appearAnimation.restart();
    }
    ParallelAnimation {
        id: appearAnimation
        NumberAnimation {
            target: root
            property: "appearScale"
            from: 0.6
            to: 1
            duration: Appearance.animation.elementMoveEnter.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
        NumberAnimation {
            target: root
            property: "appearOpacity"
            from: 0
            to: 1
            duration: Appearance.animation.elementMoveFast.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.expressiveEffects
        }
    }

    Item {
        id: contentContainer
        anchors.fill: parent
        scale: root.targetScale * root.appearScale
        opacity: root.appearOpacity
        transform: Translate {
            x: (root.liftOffset + root.bounceOffset) * root.liftVector.x
            y: (root.liftOffset + root.bounceOffset) * root.liftVector.y
        }
    }
}
