import QtQuick
import QtQuick.Controls
import ".."

Flickable {
    id: root
    maximumFlickVelocity: 3500

    property real touchpadScrollFactor: Config?.options.interactions.scrolling.touchpadScrollFactor ?? 100
    property real mouseScrollFactor: Config?.options.interactions.scrolling.mouseScrollFactor ?? 50
    property real mouseScrollDeltaThreshold: Config?.options.interactions.scrolling.mouseScrollDeltaThreshold ?? 120
    property real scrollTargetY: 0
    property bool expressiveScroll: false
    property real maxOverscroll: 56

    property bool momentumScroll: false
    property real momentumFactor: 1.0
    property real momentumMinVelocity: 40
    property real _lastWheelTime: 0
    property real _scrollVelocity: 0

    boundsBehavior: root.expressiveScroll ? Flickable.OvershootBounds : Flickable.DragOverBounds

    ScrollBar.vertical: StyledScrollBar {}

    MouseArea {
        visible: !root.expressiveScroll && !root.momentumScroll && Config?.options.interactions.scrolling.fasterTouchpadScroll
        enabled: visible
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            programmaticScroll.stop();
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;

            const maxY = Math.max(0, root.contentHeight - root.height);
            const base = scrollAnim.running ? root.scrollTargetY : root.contentY;
            var targetY = Math.max(0, Math.min(base - delta * scrollFactor, maxY));

            root.scrollTargetY = targetY;
            root.contentY = targetY;
            wheelEvent.accepted = true;
        }
    }

    function scrollToY(y) {
        const maxY = Math.max(0, root.contentHeight - root.height);
        const target = Math.max(0, Math.min(y, maxY));
        settleAnim.stop();
        bounceAnim.stop();
        programmaticScroll.stop();
        root.scrollTargetY = target;
        programmaticScroll.from = root.contentY;
        programmaticScroll.to = target;
        programmaticScroll.start();
    }
    NumberAnimation {
        id: programmaticScroll
        target: root
        property: "contentY"
        duration: Appearance.animation.scroll.duration
        easing.type: Appearance.animation.scroll.type
        easing.bezierCurve: Appearance.animation.scroll.bezierCurve
    }
    onMovementStarted: programmaticScroll.stop()
    Behavior on contentY {
        enabled: !root.expressiveScroll && !root.momentumScroll
        NumberAnimation {
            id: scrollAnim
            duration: Appearance.animation.scroll.duration
            easing.type: Appearance.animation.scroll.type
            easing.bezierCurve: Appearance.animation.scroll.bezierCurve
        }
    }

    onContentYChanged: {
        if (!scrollAnim.running && !root.expressiveScroll) {
            root.scrollTargetY = root.contentY;
        }
    }

    MouseArea {
        visible: root.expressiveScroll
        enabled: visible
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        onWheel: function(wheelEvent) {
            programmaticScroll.stop();
            const maxY = Math.max(0, root.contentHeight - root.height);
            var scrollFactor = Math.abs(wheelEvent.angleDelta.y) >= root.mouseScrollDeltaThreshold ? root.mouseScrollFactor : root.touchpadScrollFactor;
            const delta = wheelEvent.angleDelta.y / root.mouseScrollDeltaThreshold;

            const anchoredY = (settleAnim.running || bounceAnim.running) ? root.scrollTargetY : root.contentY;
            const raw = anchoredY - delta * scrollFactor;
            const scrollingDown = raw > anchoredY;
            const atBottom = anchoredY >= maxY - 0.5;
            const atTop = anchoredY <= 0.5;

            if ((scrollingDown && atBottom) || (!scrollingDown && atTop)) {
                const bound = scrollingDown ? maxY : 0;
                const overshoot = Math.min(Math.abs(raw - bound) * 0.35, root.maxOverscroll);
                root.scrollTargetY = bound;
                settleAnim.stop();
                bounceAnim.overshootY = bound + (scrollingDown ? overshoot : -overshoot);
                bounceAnim.boundY = bound;
                bounceAnim.restart();
            } else {
                const target = Math.max(0, Math.min(raw, maxY));
                root.scrollTargetY = target;
                bounceAnim.stop();
                settleAnim.stop();
                settleAnim.to = target;
                settleAnim.start();
            }
            wheelEvent.accepted = true;
        }
    }

    NumberAnimation {
        id: settleAnim
        target: root
        property: "contentY"
        duration: Appearance.animation.elementMoveSmall.duration
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.animation.elementMoveSmall.bezierCurve
    }

    SequentialAnimation {
        id: bounceAnim
        property real overshootY: 0
        property real boundY: 0
        NumberAnimation {
            target: root; property: "contentY"; to: bounceAnim.overshootY
            duration: Appearance.animation.scale(Appearance.animationCurves.expressiveEffectsDuration)
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animationCurves.emphasizedDecel
        }
        NumberAnimation {
            target: root; property: "contentY"; to: bounceAnim.boundY
            duration: Appearance.animation.elementMove.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.animation.elementMove.bezierCurve
        }
    }

    WheelHandler {
        id: momentumWheel
        enabled: root.momentumScroll
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: function(wheelEvent) {
            programmaticScroll.stop();
            const maxY = Math.max(0, root.contentHeight - root.height);
            const px = wheelEvent.pixelDelta.y;
            const ang = wheelEvent.angleDelta.y;

            if (px === 0 && ang === 0) {
                var vEnd = root._scrollVelocity;
                root._scrollVelocity = 0;
                root._lastWheelTime = 0;
                if (Math.abs(vEnd) >= root.momentumMinVelocity) {
                    vEnd = Math.max(-root.maximumFlickVelocity, Math.min(vEnd, root.maximumFlickVelocity));
                    root.flick(0, vEnd);
                }
                wheelEvent.accepted = true;
                return;
            }

            if (px === 0) {
                root.cancelFlick();
                const step = ang / 120 * root.mouseScrollFactor;
                root.contentY = Math.max(0, Math.min(root.contentY - step, maxY));
                root._scrollVelocity = 0;
                wheelEvent.accepted = true;
                return;
            }

            const now = Date.now();
            var dt = (now - root._lastWheelTime) / 1000;
            root._lastWheelTime = now;
            if (dt <= 0 || dt > 0.1) dt = 0.016;

            root.cancelFlick();
            const move = px * root.momentumFactor;
            root.contentY = Math.max(0, Math.min(root.contentY - move, maxY));

            const instant = move / dt;
            root._scrollVelocity = 0.6 * root._scrollVelocity + 0.4 * instant;
            momentumEndTimer.restart();
            wheelEvent.accepted = true;
        }
    }

    Timer {
        id: momentumEndTimer
        interval: 60
        onTriggered: {
            var v = root._scrollVelocity;
            root._scrollVelocity = 0;
            if (Math.abs(v) < root.momentumMinVelocity)
                return;
            v = Math.max(-root.maximumFlickVelocity, Math.min(v, root.maximumFlickVelocity));
            root.flick(0, v);
        }
    }
}
