import QtQuick
import Quickshell
import "../../../../services/lib/screens.js" as Screens
import "upstream" as Mac

Item {
    id: scene
    property var modelData: null

    width: 0
    height: 0

    readonly property bool isPrimary: {
        const screens = Screens.uniqueByName(Quickshell.screens)
        return screens.length > 0 && !!scene.modelData
            && screens[0].name === scene.modelData.name
    }

    Loader {
        active: scene.isPrimary
        onLoaded: {
            if (Quickshell.env("RYOKU_MACSHELL_PROBE"))
                console.log("MACSHELL_NESTED_READY " + Quickshell.env("RYOKU_MACSHELL_PROBE"));
        }
        sourceComponent: Component {
            Item {
                width: 0
                height: 0
                Mac.MacRoot {}
            }
        }
    }
}
