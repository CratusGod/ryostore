import QtQuick
import "../../.."
import "../../common"
import "../../common/functions/edit_mode.js" as EditMode

QtObject {
    id: root

    readonly property Connections drops: Connections {
        target: GlobalStates
        function onEditWidgetDroppedOnDrawer(pluginId) {
            root.removeWidget(pluginId);
        }
    }

    function removeWidget(pluginId) {
        if (!GlobalStates.editMode || pluginId === "") return;
        if (!Config.options.plugins.enabled.includes(pluginId)) return;
        const before = EditMode.listCopy(Config.options.plugins.enabled);
        GlobalStates.editUndoPush(() =>
            Config.setNestedValue("plugins.enabled", before));
        Config.setNestedValue("plugins.enabled",
            EditMode.enabledWithout(Config.options.plugins.enabled, pluginId));
    }
}
