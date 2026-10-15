import QtQuick
import "../../../.."
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"

QuickToggleModel {
    id: root

    name: Translation.tr("Phone")
    icon: "smartphone"
    hasStatusText: false
    toggled: GlobalStates.sidebarLeftOpen && GlobalStates.sidebarLeftTab === "phone"

    mainAction: null
    hasMenu: true

    tooltipText: Translation.tr("Phone | Click to open the phone tab")
}
