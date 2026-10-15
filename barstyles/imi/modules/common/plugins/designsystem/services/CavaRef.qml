import QtQuick

QtObject {
    id: root

    property bool active: true
    property bool held: false

    function sync() {
        if (root.active === root.held) return;
        CavaService.refCount += root.active ? 1 : -1;
        root.held = root.active;
    }

    onActiveChanged: root.sync()
    Component.onCompleted: root.sync()
    Component.onDestruction: {
        if (!root.held) return;
        CavaService.refCount--;
        root.held = false;
    }
}
