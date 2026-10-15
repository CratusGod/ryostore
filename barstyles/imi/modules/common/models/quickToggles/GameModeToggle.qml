import QtQuick
import "../../../../services"
import shell.services as RyokuServices

QuickToggleModel {
    name: Translation.tr("Game mode")
    toggled: RyokuServices.Toggles.gameMode
    icon: "gamepad"

    mainAction: () => RyokuServices.Toggles.toggleGame()

    tooltipText: Translation.tr("Game mode")
}
