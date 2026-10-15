import QtQuick
import Quickshell
import "../../.."
import "../../../services"
import "../../common"

Scope {
    id: root

    Variants {
        model: Quickshell.screens
        delegate: Loader {
            id: surfaceLoader
            required property var modelData
            readonly property var thisMonitorData: HyprlandData.monitors.find(monitor =>
                monitor.name === surfaceLoader.modelData?.name)
            readonly property bool specialShown:
                (surfaceLoader.thisMonitorData?.specialWorkspace?.name ?? "") !== ""

            active: GlobalStates.editMode || GlobalStates.editProgress > 0

            sourceComponent: EditModeChromeSurface {
                screen: surfaceLoader.modelData
                underneath: surfaceLoader.specialShown
            }
        }
    }

    EditWidgetMenu {}

    EditModeDrawerDrop {}
}
