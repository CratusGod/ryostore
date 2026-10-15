import Quickshell
import QtQuick

Item {
    id: root
    visible: false
    property string appId: ""
    property var entry: root.appId !== "" ? DesktopEntries.heuristicLookup(root.appId) : null

    Connections {
        target: DesktopEntries
        function onApplicationsChanged() {
            root.entry = root.appId !== "" ? DesktopEntries.heuristicLookup(root.appId) : null
        }
    }
}
