import QtQuick
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"
import shell.services as RyokuServices

QuickToggleModel {
    name: Translation.tr("Keep awake")

    toggled: RyokuServices.Toggles.keepAwake
    icon: "coffee"
    mainAction: () => RyokuServices.Toggles.toggleCaffeine()
    tooltipText: Translation.tr("Keep system awake")
}
