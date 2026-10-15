pragma ComponentBehavior: Bound

import ".."
import "../../../services"
import QtQuick
import Quickshell

StyledListView { 
    id: root
    property bool popup: false
    property NotificationController controller: NotificationController {}

    spacing: 4 * Appearance.effectiveScale

    model: ScriptModel {
        values: root.controller.appNames(root.popup)
    }
    delegate: NotificationGroup {
        required property int index
        required property var modelData
        popup: root.popup
        controller: root.controller
        width: ListView.view.width
        
        isFirst: index === 0
        isLast: index === ListView.view.count - 1
        
        notificationGroup: root.controller.groupForApp(modelData, root.popup)
    }
}
