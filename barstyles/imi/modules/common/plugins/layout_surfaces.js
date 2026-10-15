.pragma library


var DESKTOP = "desktop";
var LOCK = "lock";

function storeKey(surface) {
    return surface === LOCK ? "lockPositions" : "desktopPositions";
}

function isForked(state, screenName) {
    var lock = state && state.lockPositions;
    return !!(lock && typeof lock === "object" && lock[screenName]
        && typeof lock[screenName] === "object");
}

function rawPosition(state, surface, screenName, pluginId) {
    if (!state || !screenName || !pluginId)
        return undefined;
    if (surface === LOCK && isForked(state, screenName)) {
        var lockScreen = state.lockPositions[screenName];
        return lockScreen[pluginId];
    }
    var desktop = state.desktopPositions;
    var desktopScreen = desktop && typeof desktop === "object" ? desktop[screenName] : undefined;
    return desktopScreen && typeof desktopScreen === "object" ? desktopScreen[pluginId] : undefined;
}

function rawGridSize(state, surface, screenName, pluginId) {
    if (surface === LOCK && isForked(state, screenName)) {
        var record = state.lockPositions[screenName][pluginId];
        if (record && typeof record === "object" && record.gridSize !== undefined)
            return record.gridSize;
    }
    var options = state && state.pluginOptions;
    var plugin = options && typeof options === "object" ? options[pluginId] : undefined;
    return plugin && typeof plugin === "object" ? plugin.__gridSize : undefined;
}

function forkedScreen(state, screenName) {
    var desktopScreen = (state && state.desktopPositions
        && state.desktopPositions[screenName]) || {};
    var screen = {};
    for (var pluginId in desktopScreen) {
        var record = Object.assign({}, desktopScreen[pluginId]);
        var span = rawGridSize(state, DESKTOP, screenName, pluginId);
        if (span !== undefined)
            record.gridSize = span;
        screen[pluginId] = record;
    }
    return screen;
}

function withPosition(state, surface, screenName, pluginId, value) {
    var next = Object.assign({}, state || {});
    var key = storeKey(surface);
    var store = Object.assign({}, next[key] || {});
    var screen = (surface === LOCK && !isForked(state, screenName))
        ? forkedScreen(state, screenName)
        : Object.assign({}, store[screenName] || {});
    var previous = screen[pluginId];
    var record = Object.assign({}, value);
    if (surface === LOCK && previous && typeof previous === "object"
            && previous.gridSize !== undefined && record.gridSize === undefined)
        record.gridSize = previous.gridSize;
    screen[pluginId] = record;
    store[screenName] = screen;
    next[key] = store;
    return next;
}

function withGridSize(state, surface, screenName, pluginId, value) {
    var next = Object.assign({}, state || {});
    if (surface !== LOCK) {
        var options = Object.assign({}, next.pluginOptions || {});
        var plugin = Object.assign({}, options[pluginId] || {});
        if (value === null || value === undefined) delete plugin.__gridSize;
        else plugin.__gridSize = value;
        options[pluginId] = plugin;
        next.pluginOptions = options;
        return next;
    }
    var store = Object.assign({}, next.lockPositions || {});
    var screen = isForked(state, screenName)
        ? Object.assign({}, store[screenName] || {})
        : forkedScreen(state, screenName);
    var record = Object.assign({}, screen[pluginId] || {});
    if (value === null || value === undefined) delete record.gridSize;
    else record.gridSize = value;
    screen[pluginId] = record;
    store[screenName] = screen;
    next.lockPositions = store;
    return next;
}


function isMap(value) {
    return !!(value && typeof value === "object" && typeof value.length !== "number");
}

function containsId(list, pluginId) {
    if (!list || typeof list.length !== "number")
        return false;
    for (var i = 0; i < list.length; i++) {
        if (list[i] === pluginId)
            return true;
    }
    return false;
}

function isPresenceForked(state) {
    return isMap(state && state.lockPresence);
}

function forkedPresence(desktopEnabled) {
    var presence = {};
    if (desktopEnabled && typeof desktopEnabled.length === "number") {
        for (var i = 0; i < desktopEnabled.length; i++)
            presence[desktopEnabled[i]] = true;
    }
    return presence;
}

function lockPresent(state, desktopEnabled, pluginId) {
    if (!pluginId)
        return false;
    if (isPresenceForked(state))
        return state.lockPresence[pluginId] === true;
    return containsId(desktopEnabled, pluginId);
}

function withLockPresence(state, desktopEnabled, pluginId, present) {
    var next = Object.assign({}, state || {});
    var presence = isPresenceForked(state)
        ? Object.assign({}, state.lockPresence)
        : forkedPresence(desktopEnabled);
    if (present)
        presence[pluginId] = true;
    else
        delete presence[pluginId];
    next.lockPresence = presence;
    return next;
}

function withoutLockPresence(state) {
    if (!isPresenceForked(state))
        return state;
    var next = Object.assign({}, state);
    next.lockPresence = null;
    return next;
}

function withoutLockLayout(state, screenName) {
    if (!isForked(state, screenName))
        return state;
    var next = Object.assign({}, state);
    var lock = Object.assign({}, state.lockPositions);
    delete lock[screenName];
    next.lockPositions = lock;
    return next;
}
