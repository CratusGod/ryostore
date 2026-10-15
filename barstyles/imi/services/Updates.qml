pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import shell.services as RyokuServices

Singleton {
    id: root

    readonly property int count: RyokuServices.Updates.pending
    readonly property bool checking: false

    function refresh(): void {
        RyokuServices.Updates.check();
    }
}
