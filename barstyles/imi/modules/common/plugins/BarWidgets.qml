pragma Singleton

import QtQuick
import Quickshell
import "../../../services"

Singleton {
    id: root

    readonly property var staticWidgets: [
        { id: "leftSidebarButton", name: Translation.tr("Left Sidebar Button"),  icon: "left_panel_open" },
        { id: "rightSidebarButton", name: Translation.tr("Right Sidebar Button"), icon: "right_panel_open" },
        { id: "workspaces",        name: Translation.tr("Workspaces"),           icon: "steppers" },
        { id: "weatherBar",        name: Translation.tr("Weather"),              icon: "flare" },
        { id: "media",             name: Translation.tr("Media"),                icon: "music_note" },
        { id: "resources",         name: Translation.tr("Resources"),            icon: "empty_dashboard" },
        { id: "systemIcons",       name: Translation.tr("System Icons"),         icon: "info" },
        { id: "submapIndicator",   name: Translation.tr("Submap"),               icon: "keyboard" },
        { id: "clockWidget",       name: Translation.tr("Clock"),                icon: "schedule" },
        { id: "utilButtons",       name: Translation.tr("Util Buttons"),         icon: "toggle_on" },
        { id: "sysTray",           name: Translation.tr("Tray"),                 icon: "inbox" },
        { id: "activeWindow",      name: Translation.tr("Active Window"),        icon: "subtitles" },
        { id: "docktoPanel",       name: Translation.tr("Dock to Panel"),        icon: "apps" },
        { id: "visualizer",        name: Translation.tr("Visualizer"),           icon: "graphic_eq" },
        { id: "hyprlandXkbIndicator",   name: Translation.tr("Keyboard Layout"), icon: "keyboard" },
        { id: "divisor",            name: Translation.tr("Divider"),             icon: "horizontal_distribute" },
    ]

    readonly property var pluginWidgets: PluginManager.availablePlugins
        .filter(plugin => plugin.barWidget !== undefined)
        .map(plugin => ({
            id: "plugin:" + plugin.id,
            name: plugin.name,
            icon: plugin.icon || "extension"
        }))

    readonly property var available: staticWidgets.concat(pluginWidgets)

    function nameFor(id) {
        const found = root.available.find(entry => entry.id === id)
        return found ? found.name : id
    }

    function offerFor(usedIds, borderless) {
        const multipleAllowed = ["visualizer", "divisor"]
        const used = []
        const count = usedIds && typeof usedIds.length === "number" ? usedIds.length : 0
        for (let i = 0; i < count; i++)
            used.push(usedIds[i])
        return root.available.filter(entry => {
            if (entry.id === "divisor" && borderless !== "transparent")
                return false
            return used.indexOf(entry.id) === -1 || multipleAllowed.indexOf(entry.id) !== -1
        })
    }
}
