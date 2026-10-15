import QtQuick
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"
import shell.services as RyokuServices

QuickToggleModel {
    property bool auto: RyokuServices.Nightlight.schedule !== "off"

    name: Translation.tr("Night Light")
    statusText: (auto ? Translation.tr("Auto, ") : "") + (toggled ? Translation.tr("Active") : Translation.tr("Inactive"))

    toggled: RyokuServices.Nightlight.on
    icon: auto ? "night_sight_auto" : "bedtime"

    mainAction: () => RyokuServices.Nightlight.toggle()
    hasMenu: true

    tooltipText: Translation.tr("Night Light | Right-click to configure")
}
