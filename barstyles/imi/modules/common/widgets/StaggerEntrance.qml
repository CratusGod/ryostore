import QtQuick
import ".."

QtObject {
    id: root

    property Item target: null

    property real reference: 0

    readonly property real rise: Appearance.animation.entranceRise
    readonly property real scaleFrom: root.convergent
        ? Appearance.animation.convergeScaleFrom
        : Appearance.animation.entranceScaleFrom(
              root.reference > 0 ? root.reference : (root.target?.width ?? 0))

    property bool convergent: false

    property Component lift: Component {
        Translate {
            objectName: "staggerEntranceLift"
            property Item item
            readonly property real settle: root.convergent
                ? Appearance.animation.convergeSettle(item?.appear ?? 1)
                : (item?.appear ?? 1)
            readonly property var direction: {
                if (!root.convergent || !item || !root.target || root.target.width <= 0)
                    return { dx: 0, dy: -1 };
                const centre = (item.x + item.width / 2) / root.target.width * 2 - 1;
                return Appearance.animation.convergeFrom(centre, root.memberParity(item));
            }
            x: root.convergent
                ? (1 - settle) * direction.dx * Appearance.animation.convergeReachX
                : 0
            y: root.convergent
                ? (1 - settle) * direction.dy * Appearance.animation.convergeReachY
                : (1 - settle) * root.rise
        }
    }

    function memberParity(child: Item): int {
        const kids = members();
        let rank = 0;
        for (let i = 0; i < kids.length; i++) {
            if (kids[i] === child)
                return rank;
            if (kids[i]?.appear !== undefined && kids[i].visible)
                rank++;
        }
        return rank;
    }

    function members(): var {
        return root.target ? root.target.children : [];
    }

    function dressed(child: Item): bool {
        for (let i = 0; i < child.transform.length; i++)
            if (child.transform[i]?.objectName === "staggerEntranceLift")
                return true;
        return false;
    }

    function dress() {
        const kids = root.target ? root.target.children : [];
        for (let i = 0; i < kids.length; i++) {
            const child = kids[i];
            if (child.appear === undefined)
                continue;
            if (root.dressed(child))
                continue;
            if (child.interactionMotion !== undefined) {
                if (root.convergent)
                    child.transform.push(root.lift.createObject(child, { item: child }));
                continue;
            }
            child.opacity = Qt.binding(() => child.appear);
            child.scale = Qt.binding(() =>
                root.scaleFrom + (1 - root.scaleFrom) *
                (root.convergent ? Appearance.animation.convergeSettle(child.appear) : child.appear));
            child.transform.push(root.lift.createObject(child, { item: child }));
        }
    }

    property Connections arrivals: Connections {
        target: root.target
        function onChildrenChanged() {
            root.dress();
        }
    }

    Component.onCompleted: root.dress()
}
