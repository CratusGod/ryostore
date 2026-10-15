.pragma library


const PLUGIN_PREFIX = "plugin:";

const NATIVE_BAR_COMPONENTS = {
    "docker_plugin": "DockerPlugin.qml",
    "discord_voice": "DiscordVoicePlugin.qml"
};

const PACKAGE_BAR_COMPONENT = "PluginBarWidget.qml";

function pluginIdOf(name) {
    if (!name || !name.startsWith(PLUGIN_PREFIX))
        return "";
    return name.substring(PLUGIN_PREFIX.length);
}

function nativeComponentFor(pluginId) {
    return Object.prototype.hasOwnProperty.call(NATIVE_BAR_COMPONENTS, pluginId)
        ? NATIVE_BAR_COMPONENTS[pluginId]
        : "";
}

function fileNameFor(name) {
    if (!name)
        return "";
    const pluginId = pluginIdOf(name);
    if (pluginId)
        return nativeComponentFor(pluginId) || PACKAGE_BAR_COMPONENT;
    return name.charAt(0).toUpperCase() + name.slice(1) + ".qml";
}

function isDisabledPlugin(name, enabledPluginIds) {
    const pluginId = pluginIdOf(name);
    if (!pluginId)
        return false;
    for (let i = 0; i < enabledPluginIds.length; i++) {
        if (enabledPluginIds[i] === pluginId)
            return false;
    }
    return true;
}
