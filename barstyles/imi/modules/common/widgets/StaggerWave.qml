pragma ComponentBehavior: Bound

import QtQuick
import ".."

QtObject {
    id: root

    property Item target: null

    property int step: Appearance.animation.staggerStep
    property int leadIn: 0

    property var active: []

    property bool pendingEnter: false
    property Connections targetVisibility: Connections {
        target: root.target
        function onVisibleChanged() {
            if (root.pendingEnter && root.target?.visible)
                root.enter();
        }
    }

    property list<Item> items

    function members(): var {
        if (root.items.length > 0)
            return root.items;
        return root.target ? root.target.children : [];
    }

    function stop() {
        for (let i = 0; i < root.active.length; i++) {
            const spent = root.active[i];
            if (!spent)
                continue;
            spent.stop();
            spent.destroy();
        }
        root.active = [];
    }

    function park() {
        root.stop();
        root.pendingEnter = false;
        const kids = root.members();
        for (let i = 0; i < kids.length; i++)
            if (kids[i].appear !== undefined)
                kids[i].appear = 0;
    }

    function settle() {
        root.stop();
        root.pendingEnter = false;
        const kids = root.members();
        for (let i = 0; i < kids.length; i++)
            if (kids[i].appear !== undefined)
                kids[i].appear = 1;
    }

    function enter() {
        root.stop();
        const kids = root.members();

        if (!root.target?.visible) {
            root.park();
            root.pendingEnter = true;
            return;
        }
        root.pendingEnter = false;

        const wave = [];

        const included = [];
        for (let i = 0; i < kids.length; i++)
            included.push(kids[i].appear !== undefined && kids[i].visible);
        const ranks = Appearance.animation.staggerRanks(included);
        const step = Appearance.animation.scale(root.step);
        const leadIn = Appearance.animation.scale(root.leadIn);

        for (let i = 0; i < kids.length; i++) {
            if (ranks[i] < 0) {
                if (kids[i].appear !== undefined)
                    kids[i].appear = 1;
                continue;
            }
            kids[i].appear = 0;
            wave.push(root.fade.createObject(root, {
                item: kids[i],
                to: 1,
                span: Appearance.animation.elementMoveFast.duration,
                delay: Appearance.animation.staggerDelay(ranks[i], step, leadIn)
            }));
        }

        root.active = wave;
        for (let i = 0; i < wave.length; i++)
            wave[i].start();
    }

    function leave() {
        root.stop();
        root.pendingEnter = false;
        const kids = root.members();
        const wave = [];
        for (let i = 0; i < kids.length; i++) {
            if (kids[i].appear === undefined)
                continue;
            wave.push(root.fade.createObject(root, {
                item: kids[i],
                delay: 0,
                to: 0,
                span: Appearance.animation.elementMoveExit.duration
            }));
        }
        root.active = wave;
        for (let i = 0; i < wave.length; i++)
            wave[i].start();
    }

    function run(entering: bool) {
        if (entering)
            root.enter();
        else
            root.leave();
    }

    property Component fade: Component {
        SequentialAnimation {
            id: seq
            property Item item
            property int delay: 0
            property real to: 1
            property int span: 200
            PauseAnimation { duration: seq.delay }
            NumberAnimation {
                target: seq.item
                property: "appear"
                to: seq.to
                duration: seq.span
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.animationCurves.expressiveEffects
            }
            onFinished: {
                root.active = root.active.filter(member => member !== seq);
                seq.destroy();
            }
        }
    }
}
