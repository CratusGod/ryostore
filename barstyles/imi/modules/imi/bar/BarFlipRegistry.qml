import QtQuick

Item {
    id: root

    readonly property Item frame: root.parent

    visible: false
    width: 0
    height: 0

    property var positions: ({})

    function deposit(widgetId, point) {
        if (!widgetId || !point) return;
        root.positions[widgetId] = point;
        expiry.restart();
    }

    function recall(widgetId) {
        if (!widgetId) return null;
        const point = root.positions[widgetId];
        return point === undefined ? null : point;
    }

    Timer {
        id: expiry
        interval: 0
        onTriggered: root.positions = ({})
    }
}
