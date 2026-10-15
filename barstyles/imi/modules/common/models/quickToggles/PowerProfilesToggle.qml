import QtQuick
import "../../../../services"
import "../.."
import "../../functions"
import "../../widgets"
import shell.services as RyokuServices

QuickToggleModel {
    id: root

    readonly property string profile: RyokuServices.PowerProfiles.profile

    name: Translation.tr("Power Profile")
    available: RyokuServices.PowerProfiles.available
    toggled: root.profile !== "balanced"
    icon: root.profile === "power-saver" ? "energy_savings_leaf"
        : root.profile === "performance" ? "local_fire_department"
        : "airwave"
    statusText: root.profile === "power-saver" ? "Power Saver"
        : root.profile === "performance" ? "Performance"
        : "Balanced"

    mainAction: () => {
        const profiles = RyokuServices.PowerProfiles.profiles;
        const index = profiles.indexOf(root.profile);
        RyokuServices.PowerProfiles.setProfile(profiles[(Math.max(0, index) + 1) % profiles.length]);
    }
    tooltipText: Translation.tr("Click to cycle through power profiles")
}
